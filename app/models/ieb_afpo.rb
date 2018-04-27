class IebAfpo < ActiveRecord::Base
  self.primary_key = 'aufnr'
  belongs_to :ieb_bom, class_name: 'IebBom', foreign_key: 'ieb_bom_id'

  ERR_STATUS = {
      'A' => '展BOM錯誤',
      'B' => '完成展BOM'

  }

  def open_so_products
    products = Array.new
    list = IebAfpo.find_by_sql 'SELECT DISTINCT MATNR FROM SAP_VBBE381A'
    list.each do |row|
      products.append row.matnr
    end
    return products
  end

  def product_order_stocks

    #get open order finish goods material numer store it as array
    products = open_so_products

    sql = "WITH A
           AS (SELECT DISTINCT B.AUFNR, C.WERKS
                 FROM SAPSR3.MCHB C, SAPSR3.MSEG B
                WHERE C.MANDT = '168' AND C.WERKS = (?)
                      AND (C.CLABS + C.CUMLM + C.CINSM + C.CEINM + C.CSPEM + C.CRETM) >
                             0
                      AND B.MANDT = '168'
                      AND B.MATNR = C.MATNR
                      AND B.CHARG = C.CHARG
                      AND B.BWART = '101'
                      AND B.AUFNR <> ' ')
      SELECT B.AUFNR, B.MATNR, B.PSMNG, B.WEMNG, A.WERKS
        FROM SAPSR3.AFPO B, A
       WHERE B.MANDT = '168' AND B.AUFNR = A.AUFNR"
    list = Sapdb.find_by_sql [sql, Figaro.env.bond_werks]
    list.each do |sap_afpo|
      update_order_qty sap_afpo if products.include?(sap_afpo.matnr)
    end
    batch_bom_allocations(IebAfpo.where(ieb_bom_id: nil))
  end

  def update_order_qty (sap_afpo)
    afpo = IebAfpo.where(aufnr: sap_afpo.aufnr).first
    if afpo.nil?
      IebAfpo.create(
          aufnr: sap_afpo.aufnr,
          matnr: sap_afpo.matnr,
          psmng: sap_afpo.psmng,
          wemng: sap_afpo.wemng,
          werks: sap_afpo.werks,
          received: true,
          received_at: Time.now,
          finished: sap_afpo.psmng == sap_afpo.wemng,
          finished_at: (Time.now if sap_afpo.psmng == sap_afpo.wemng)
      )
    else
      afpo.psmng = sap_afpo.psmng
      afpo.wemng = sap_afpo.wemng
      afpo.finished = sap_afpo.psmng == sap_afpo.wemng
      afpo.finished_at = Time.now if sap_afpo.psmng == sap_afpo.wemng
      afpo.save
    end
    return afpo
  end

  def create_ieb_afpo(aufnr)
    afpos = Array.new
    sql = "SELECT B.AUFNR, B.MATNR, B.PSMNG, B.WEMNG, B.PWERK WERKS FROM SAPSR3.AFPO B WHERE B.MANDT = '168' AND B.AUFNR IN (?)"
    list = Sapdb.find_by_sql [sql, aufnr]
    list.each do |sap_afpo|
      update_order_qty sap_afpo
      afpos.append aufnr
    end
    batch_bom_allocations(afpos)
  end

  def batch_bom_allocations(afpos)
    afpos.each do |afpo|
      begin
        IebAfpo.transaction do
          parts, procurement_parts = parts_and_procurement_parts afpo.aufnr
          afpo.home_made_parts = parts.join(',')
          afpo.procurement_parts = procurement_parts.join(',')
          partsx = Array.new
          parts.each { |row| partsx.append purchase_part row }
          boms = Array.new
          sbomtb = SapSbomtb.new
          sbomtb.bom_explosion(afpo.werks, afpo.matnr, 1, boms, parts, partsx, procurement_parts)
          bom = IebBom.new
          bom.matnr = afpo.matnr
          bom.connr = Figaro.env.connr
          bom.home_made_parts = afpo.home_made_parts
          bom.procurement_parts = afpo.procurement_parts
          if boms.empty?
            afpo.message = '沒有標準BOM!, 請文管建立標準BOM'
          else
            afpo.ieb_bom_id, afpo.message = bom.match_or_create(boms)
            update_sap_zieba011(afpo) unless afpo.ieb_bom_id.nil?
          end
          afpo.save
        end
      rescue Exception => ex
        puts ex.message
      end
    end
  end


  def update_sap_zieba011(afpo)
    sql = "SELECT RMSTU FROM SAPSR3.ZIEBA011 WHERE MANDT='168' AND AUFNR=?"
    rows = Sapdb.find_by_sql [sql, afpo.aufnr]
    if rows.empty?
      attributes = {
          AUFNR: afpo.aufnr,
          BNAREA: Figaro.env.bnarea,
          BUKRS: Figaro.env.bukrs,
          MOSTU: '3',
          VERNR2: afpo.ieb_bom.vernr,
          RMSTU: '1',
          CRDAT: Time.now.strftime('%Y%m%d'),
          CRTIME: Time.now.strftime('%H%M%S'),
          CRNAM: 'LUM.LIN',
          AEDAT: Time.now.strftime('%Y%m%d'),
          AETIME: Time.now.strftime('%H%M%S'),
          AENAM: 'LUM.LIN'
      }
      SapSe16n.create_transaction('ZIEBA011', 'INSERT', {}, attributes)
    else
      selections = {
          AUFNR: afpo.aufnr
      }

      attributes = {
          MOSTU: '3',
          VERNR2: afpo.ieb_bom.vernr,
          RMSTU: '1',
          AEDAT: Time.now.strftime('%Y%m%d'),
          AETIME: Time.now.strftime('%H%M%S'),
          AENAM: 'LUM.LIN'
      }
      SapSe16n.create_transaction('ZIEBA011', 'UPDATE', selections, attributes)
    end
    afpo.sap_updated = true
    afpo.sap_updated_at = Time.now
  end


  def parts_and_procurement_parts (aufnr)
    sql = "
            SELECT MATNR, WERKS, BDMNG, ENMNG, ESMNG, AUSCH, MEINS, POSNR, VORNR, ALPOS,
                 ALPGR, EWAHR, DUMPS, BAUGR, HRKFT, MATKL
            FROM SAPSR3.RESB
           WHERE MANDT = '168' AND AUFNR = ? AND (SUBSTR(POSNR,1,1) <> 'Z' OR SUBSTR(AUFNR,1,4) = '0013')
        ORDER BY VORNR, POSNR, ALPOS, ALPGR, EWAHR
    "
    list = Sapdb.find_by_sql [sql, aufnr]

    #1 search for lei & sub
    home_made_parts = Array.new
    list.each { |row|
      home_made_parts.append row.matnr if row.matnr[row.matnr.size-3..row.matnr.size] == 'LEI' and row.enmng > 0 and not home_made_parts.include?(row.matnr)
      home_made_parts.append row.matnr if row.matnr[row.matnr.size-5..row.matnr.size-3] == 'SUB' and row.enmng > 0 and not home_made_parts.include?(row.matnr)
    }

    #2 search for old mo with mix home made and purchase ST
    wip_parts = Array.new
    st_matkl = %w[STH 29-01 29-02]
    st_start = %w[LS 29]
    st_wip = %w[-1 -2 -3 -4 -5 -6 -7 -8 -9]
    list.each { |row|
      if row.bdmng > 0
        if st_matkl.include?(row.matkl) and st_start.include?(row.matnr[0..1]) and
            not st_wip.include?(row.matnr[row.matnr.size-4..row.matnr.size-3]) and
            not wip_parts.include?(row.matnr)
          wip_parts.append row.matnr
        end
        wip_parts.append row.matnr if row.matnr[row.matnr.size-3..row.matnr.size] == 'LEI' and not home_made_parts.include?(row.matnr)
        wip_parts.append row.matnr if row.matnr[row.matnr.size-5..row.matnr.size-3] == 'SUB' and not home_made_parts.include?(row.matnr)
      end
    }

    #3 based on the wip parts seach for sub_component issue
    sql = "SELECT DISTINCT PMATNR,DPMATNR FROM SAP_SBOMXTB WHERE WERKS = '381A' AND PMATNR IN (?)"
    wips = IebAfpo.find_by_sql [sql, wip_parts]
    wip_parts.each do |part|
      wips.each do |wip|
        if wip.pmatnr == part
          list.each do |row|
            home_made_parts.append part if row.baugr == wip.dpmatnr and row.enmng > 0 and not home_made_parts.include?(part)
            break if home_made_parts.include?(part)
          end
        end
        break if home_made_parts.include?(part)
      end
    end

    #4 check remaining wip_issue parts is manufactured item or purchased item
    sql = "
          SELECT DISTINCT MATNR
        FROM SAPSR3.MSEG B
       WHERE B.MANDT = '168' AND B.BWART = '101' AND B.AUFNR <> ' '
             AND (B.MATNR, B.CHARG) IN
                    (  SELECT A.MATNR, A.CHARG
                         FROM SAPSR3.AUFM A
                        WHERE     A.MANDT = '168'
                              AND A.AUFNR = ?
                              AND A.MATNR IN (?)
                              AND A.BWART IN ('261', '262')
                     GROUP BY A.MATNR, A.CHARG
                       HAVING SUM (DECODE (SHKZG, 'H', MENGE, MENGE * -1)) > 0)
    "
    remaining_parts = Array.new
    wip_parts.each do |part|
      remaining_parts.append part unless home_made_parts.include?(part)
    end
    (Sapdb.find_by_sql [sql, aufnr, remaining_parts]).each do |row|
      home_made_parts.append row.matnr
    end

    sql = "
          SELECT DISTINCT MATNR
        FROM SAPSR3.MSEG B
       WHERE B.MANDT = '168' AND B.BWART = '101' AND B.EBELN <> ' '
             AND (B.MATNR, B.CHARG) IN
                    (  SELECT A.MATNR, A.CHARG
                         FROM SAPSR3.AUFM A
                        WHERE     A.MANDT = '168'
                              AND A.AUFNR = ?
                              AND A.MATNR IN (?)
                              AND A.BWART IN ('261', '262')
                     GROUP BY A.MATNR, A.CHARG
                       HAVING SUM (DECODE (SHKZG, 'H', MENGE, MENGE * -1)) > 0)
    "
    remaining_parts.clear
    wip_parts.each do |part|
      remaining_parts.append part unless home_made_parts.include?(part)
    end
    procurement_parts = Array.new
    (Sapdb.find_by_sql [sql, aufnr, remaining_parts]).each do |row|
      procurement_parts.append row.matnr
    end
    return home_made_parts.sort, procurement_parts.sort
  end


  def purchase_part (matnr)
    return matnr.split('LEI').first if matnr[matnr.size-3..matnr.size] == 'LEI'
    return matnr.split('SUB').first if matnr[matnr.size-5..matnr.size] == 'SUB00'
    matnr
  end

end
