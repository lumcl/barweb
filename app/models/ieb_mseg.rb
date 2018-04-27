class IebMseg < ActiveRecord::Base

  def self.z_insert

    rows = SapMseg.where(vgart: 'WE').where(rstat: '1')
               .where("budat between '20150901' and '20150999'")
               .order(bwart: :asc, cpudt: :asc, cputm: :asc)
    rows.each do |row|

      begin
        SapMseg.transaction do
          if row.vgart == 'WE'
            mseg = vgart_we(row)
            mseg.save!
          elsif row.vgart == 'WL'
          end
          row.rstat = '2'
          row.save!
        end
      rescue Exception => ex
        puts ex.message
      end
    end
    ''
  end

  def self.update_cbseq
    ieb_msegs = IebMseg.where(vgart: 'WE').where(cbseq: ' ')
    ieb_msegs.each do |mseg|
      sql = 'SELECT A.CONNR, A.CBTYP, A.CBSEQ, A.DLRAT, B.DEUOM, C.CUTXT
            FROM SAP_ZIEBA003 A, SAP_ZIEBC001 B, SAP_ZIEBB002 C
           WHERE     B.CONNR = A.CONNR
                 AND B.CBTYP = A.CBTYP
                 AND B.CBSEQ = A.CBSEQ
                 AND C.CUUOM = B.DEUOM
                 AND A.CONNR = ?
                 AND A.MATNR = ?'
      rows = IebZieba003.find_by_sql [sql, Figaro.env.connr, mseg.matnr]
      rows.each do |row|
        mseg.connr = row.connr
        mseg.cbseq = row.cbseq
        mseg.cbtyp = row.cbtyp
        mseg.deuom = row.deuom
        mseg.dlrat = row.dlrat
        mseg.apmng = mseg.menge * row.dlrat
        mseg.cutxt = row.cutxt
        mseg.save!
      end
    end
  end

  def self.vgart_we(sap_mseg)
    sign = sap_mseg.shkzg == 'S' ? 1 : -1

    mseg = IebMseg.new({
                           mjahr: sap_mseg.mjahr,
                           mblnr: sap_mseg.mblnr,
                           zeile: sap_mseg.zeile,
                           vgart: sap_mseg.vgart,
                           blart: sap_mseg.blart,
                           bwart: sap_mseg.bwart,
                           budat: sap_mseg.budat,
                           cpudt: sap_mseg.cpudt,
                           cputm: sap_mseg.cputm,
                           matnr: sap_mseg.matnr,
                           werks: sap_mseg.werks,
                           lgort: sap_mseg.lgort,
                           charg: sap_mseg.charg,
                           menge: sap_mseg.menge * sign,
                           meins: sap_mseg.meins,
                           dmbtr: sap_mseg.dmbtr * sign,
                           lifnr: sap_mseg.lifnr,
                           ebeln: sap_mseg.ebeln,
                           ebelp: sap_mseg.ebelp,
                           xblnr: sap_mseg.xblnr,
                           frbnr: sap_mseg.frbnr
                       })

    sql = 'SELECT A.CONNR, A.CBTYP, A.CBSEQ, A.DLRAT, B.DEUOM, C.CUTXT
            FROM SAP_ZIEBA003 A, SAP_ZIEBC001 B, SAP_ZIEBB002 C
           WHERE     B.CONNR = A.CONNR
                 AND B.CBTYP = A.CBTYP
                 AND B.CBSEQ = A.CBSEQ
                 AND C.CUUOM = B.DEUOM
                 AND A.CONNR = ?
                 AND A.MATNR = ?'
    rows = IebZieba003.find_by_sql [sql, Figaro.env.connr, mseg.matnr]
    rows.each do |row|
      mseg.connr = row.connr
      mseg.cbseq = row.cbseq
      mseg.cbtyp = row.cbtyp
      mseg.deuom = row.deuom
      mseg.dlrat = row.dlrat
      mseg.apmng = mseg.menge * row.dlrat
      mseg.cutxt = row.cutxt
    end

    if mseg.bwart == '102'or mseg.bwart == '162' or mseg.bwart == '123'
      mseg.vgart_we_reverse(mseg)

      return mseg
    end

    sql = "
      SELECT A.MBLNR, A.MJAHR, A.ZEILE, A.BWART, A.WERKS, A.LIFNR, A.EBELN, A.EBELP, A.SHKZG,
         B.XBLNR, B.FRBNR, C.WRBTR, C.WAERS, D.GJAHR, D.BELNR, D.BUZEI, D.WRBTR WRBTR_AP,
         (SELECT MIN(Z.PARVW) FROM SAPSR3.EKPA Z WHERE Z.MANDT='168' AND Z.EBELN=A.EBELN  AND Z.PARZA = '001') PARVW
    FROM SAPSR3.MSEG A, SAPSR3.MKPF B, SAPSR3.EKBE C, SAPSR3.EKBE D
   WHERE     A.MANDT = '168'
         AND A.MATNR = ?
         AND A.CHARG = ?
         AND A.BWART NOT LIKE '3%'
         AND A.LIFNR NOT IN ('L700','L100','L920')
         AND B.MANDT = '168'
         AND B.MBLNR = A.MBLNR
         AND B.MJAHR = A.MJAHR
         AND B.VGART = 'WE'
         AND C.MANDT(+) = A.MANDT
         AND C.GJAHR(+) = A.MJAHR
         AND C.BELNR(+) = A.MBLNR
         AND C.BUZEI(+) = A.ZEILE
         AND C.VGABE(+) = '1'
         AND C.MENGE(+) = A.MENGE
         AND C.BWART(+) = A.BWART
         AND D.MANDT(+) = A.MANDT
         AND D.GJAHR(+) = A.MJAHR
         AND D.BELNR(+) = A.MBLNR
         AND D.BUZEI(+) = A.ZEILE
         AND D.MENGE(+) = A.MENGE
         AND D.VGABE(+) = '2'
    "

    rows = IebMseg.find_by_sql [sql, sap_mseg.matnr, sap_mseg.charg]

    mseg.rstat = 'N'
    found = false

    rows.each do |row|
      if (row.mblnr == mseg.mblnr) and (row.mjahr == mseg.mjahr)
        mseg.vgart_we_sto(row, mseg)
        found = true
        mseg.rstat = 'A'
        break
      end
    end

    unless found
      rows.each do |row|
        if row.bwart == sap_mseg.bwart
          mseg.vgart_we_sto(row, mseg)
          found = true
          mseg.rstat = 'B'
          break
        end
      end
    end

    unless found
      rows.each do |row|
        if row.shkzg == sap_mseg.shkzg
          mseg.vgart_we_sto(row, mseg)
          found = true
          mseg.rstat = 'C'
          break
        end
      end
    end

    unless found
      sql = "
            SELECT A.MBLNR, A.MJAHR, A.ZEILE, A.BWART, A.WERKS, A.LIFNR, A.EBELN, A.EBELP, A.SHKZG,
               B.XBLNR, B.FRBNR, C.WRBTR, C.WAERS, D.GJAHR, D.BELNR, D.BUZEI, D.WRBTR WRBTR_AP,
               (SELECT MIN(Z.PARVW) FROM SAPSR3.EKPA Z WHERE Z.MANDT='168' AND Z.EBELN=A.EBELN  AND Z.PARZA = '001') PARVW
          FROM SAPSR3.MSEG A, SAPSR3.MKPF B, SAPSR3.EKBE C, SAPSR3.EKBE D
         WHERE     A.MANDT = '168'
               AND A.MBLNR = ?
               AND A.MJAHR = ?
               AND A.ZEILE = ?
               AND A.BWART NOT LIKE '3%'
               AND B.MANDT = '168'
               AND B.MBLNR = A.MBLNR
               AND B.MJAHR = A.MJAHR
               AND B.VGART = 'WE'
               AND C.MANDT(+) = A.MANDT
               AND C.GJAHR(+) = A.MJAHR
               AND C.BELNR(+) = A.MBLNR
               AND C.BUZEI(+) = A.ZEILE
               AND C.VGABE(+) = '1'
               AND C.MENGE(+) = A.MENGE
               AND C.BWART(+) = A.BWART
               AND D.MANDT(+) = A.MANDT
               AND D.GJAHR(+) = A.MJAHR
               AND D.BELNR(+) = A.MBLNR
               AND D.BUZEI(+) = A.ZEILE
               AND D.MENGE(+) = A.MENGE
               AND D.VGABE(+) = '2'
          "
      rows = IebMseg.find_by_sql [sql, sap_mseg.mblnr, sap_mseg.mjahr, sap_mseg.zeile]
      rows.each do |row|
        mseg.vgart_we_sto(row, mseg)
        found = true
        mseg.rstat = 'D'
        break
      end
    end

    return mseg
  end

  def vgart_we_reverse(mseg)
    sql = "SELECT SJAHR, SMBLN, SMBLP FROM SAPSR3.MSEG WHERE MANDT='168' AND MBLNR=? AND MJAHR=? AND ZEILE=?"
    rows = IebMseg.find_by_sql [sql, mseg.mblnr, mseg.mjahr, mseg.zeile]
    rows.each do |record|
      row = IebMseg.where(mjahr: record.sjahr).where(mblnr: record.smbln).where(zeile: record.smblp).first
      if row
        mseg.wrbtr = row.wrbtr * -1
        mseg.waers = row.waers
        mseg.parvw = row.parvw
        mseg.lifnr = row.lifnr
        mseg.ebeln = row.ebeln
        mseg.ebelp = row.ebelp
        mseg.xblnr= row.xblnr
        mseg.belnr_ap = row.belnr_ap
        mseg.buzei_ap = row.buzei_ap
        mseg.gjahr_ap = row.gjahr_ap
        mseg.rstat = row.rstat
      end
    end
  end

  def vgart_we_sto(row, mseg)

    curr_factor = (row.waers == 'NTD' or row.waers == 'JPY') ? 100 : 1
    unless mseg.ebeln == row.ebeln
      mseg.lifnr_sto = mseg.lifnr
      mseg.ebeln_sto = mseg.ebeln
      mseg.ebelp_sto = mseg.ebelp
    end

    mseg.wrbtr = row.wrbtr_ap || row.wrbtr || 0 * curr_factor
    mseg.wrbtr = mseg.wrbtr * -1 if mseg.menge < 0
    mseg.waers = row.waers
    mseg.parvw = row.parvw
    mseg.lifnr = row.lifnr
    mseg.ebeln = row.ebeln
    mseg.ebelp = row.ebelp
    mseg.xblnr= row.xblnr
    mseg.belnr_ap = row.belnr
    mseg.buzei_ap = row.buzei
    mseg.gjahr_ap = row.gjahr
  end


  def abc(sap_mseg)
    IebMseg.create!({
                        mjahr: sap_mseg.mjahr,
                        mblnr: sap_mseg.mblnr,
                        zeile: sap_mseg.zeile,
                        vgart: sap_mseg.vgart,
                        blart: sap_mseg.blart,
                        bwart: sap_mseg.bwart,
                        budat: sap_mseg.budat,
                        cpudt: sap_mseg.cpudt,
                        cputm: sap_mseg.cputm,
                        matnr: sap_mseg.matnr,
                        werks: sap_mseg.werks,
                        lgort: sap_mseg.lgort,
                        charg: sap_mseg.charg,
                        menge: sap_mseg.menge,
                        meins: sap_mseg.meins,
                        dmbtr: sap_mseg.dmbtr,
                        wrbtr: wrbtr,
                        waers: waers,
                        parvw: parvw,
                        lifnr: lifnr,
                        ebeln: ebeln,
                        ebelp: ebelp,
                        licha: licha,
                        xblnr: xblnr,
                        belnr_ap: belnr_ap,
                        buzei_ap: buzei_ap,
                        gjahr_ap: gjahr_ap,
                        guinr: guinr,
                        lifnr_sto: lifnr_sto,
                        ebeln_sto: ebeln_sto,
                        ebelp_sto: ebelp_sto,
                        belnr_sto: belnr_sto,
                        buzei_sto: buzei_sto,
                        gjahr_sto: gjahr_sto,
                        connr: connr,
                        cbseq: cbseq,
                        apmng: apmng,
                        dlrat: dlrat,
                        cutxt: cutxt
                    })

  end


  def self.insert_ziebi007
    sql = "SELECT B.MBLNR, B.MJAHR, B.ZEILE, B.LIFNR, B.BUDAT
        FROM SAPSR3.ZIEBI007 A, TXDB.IEB_MSEGS B
       WHERE     B.PARVW = 'V3'
             AND A.MBLNR(+) = B.MBLNR
             AND A.MJAHR(+) = B.MJAHR
             AND A.ZEILE(+) = B.ZEILE
             AND A.MBLNR IS NULL"

    i = 0
    rows = IebMseg.find_by_sql sql
    rows.each do |row|
      attributes = {
          MBLNR: row.mblnr,
          MJAHR: row.mjahr,
          ZEILE: row.zeile,
          BNAREA: '5207',
          BUKRS: 'L300',
          LIFNR: row.lifnr,
          BUDAT: row.budat,
          CRDAT: Time.now.strftime('%Y%m%d'),
          CRTIME: Time.now.strftime('%H%M%S'),
          CRNAM: 'LUM.LIN'
      }
      i = i + 1
      SapSe16n.create_job('ZIEBI007', 'INSERT', {}, attributes, "#{(i % 3) + 2}")
    end
    'Completed'
  end

  def self.zupdate_dtran
    sql = "SELECT A.MJAHR, A.MBLNR, A.ZEILE
        FROM TXDB.IEB_MSEGS A, SAPSR3.ZIEBI007 B
       WHERE A.PARVW = 'V3' AND A.IMPNR=' '
       AND B.MJAHR(+) = A.MJAHR AND B.MBLNR(+) = A.MBLNR AND B.ZEILE(+) = A.ZEILE
       AND B.DTRAN(+) = 'X' AND B.BUKRS='L300'"
    i = 0
    rows = IebMseg.find_by_sql sql
    rows.each do |row|
      selections = {
          MBLNR: row.mblnr,
          MJAHR: row.mjahr,
          ZEILE: row.zeile
      }
      attributes = {
          DTRAN: ' ',
          AEDAT: Time.now.strftime('%Y%m%d'),
          AETIME: Time.now.strftime('%H%M%S'),
          AENAM: 'LUM.LIN'
      }
      i = i + 1
      SapSe16n.create_job('ZIEBI007', 'UPDATE', selections, attributes, "#{(i % 4) + 1}")
    end
    'Completed'

  end

  def self.zupdate_dtran_x
    sql = "SELECT B.MBLNR,B.MJAHR,B.ZEILE
      FROM IEB_MSEGS A, SAPSR3.ZIEBI007 B
      WHERE A.IMPNR <> ' ' AND B.DTRAN = ' '
      AND B.MJAHR=A.MJAHR AND B.MBLNR=A.MBLNR AND B.ZEILE=A.ZEILE"
    i = 0
    rows = IebMseg.find_by_sql sql
    rows.each do |row|
      selections = {
          MBLNR: row.mblnr,
          MJAHR: row.mjahr,
          ZEILE: row.zeile
      }
      attributes = {
          DTRAN: 'X',
          AEDAT: Time.now.strftime('%Y%m%d'),
          AETIME: Time.now.strftime('%H%M%S'),
          AENAM: 'LUM.LIN'
      }
      i = i + 1
      SapSe16n.create_job('ZIEBI007', 'UPDATE', selections, attributes, "#{(i % 4) + 1}")
    end
    'Completed'
  end


  def self.zcreate_v3(params)
    connr = params[:connr]
    closn = params[:closn]
    corig = params[:corig]
    pktyp = params[:pktyp]
    ids = params[:ids]

    return '關封號, 關封行號不能為空!' if closn.empty?

    rows = Array.new
    min = 0
    loop do
      if (min + 1000) < ids.size
        max = min + 1000
      else
        max = ids.size
      end
      sql = "SELECT /*+ DRIVING_SITE(B) */
          A.ID, A.BUDAT, A.MJAHR, A.MBLNR, A.ZEILE, A.MATNR, A.CHARG, A.MENGE,
           A.MEINS, A.WRBTR, A.WAERS, A.CBSEQ, A.APMNG, B.HSTXT, C.CUTXT, A.LIFNR,
           (D.NETKG * MENGE) WEIGHT, A.EBELP, A.EBELN, A.CBTYP, D.MATKL, E.FSRAT
      FROM IEB_MSEGS A, SAP_ZIEBC001 B, SAP_ZIEBB002 C, SAP_MARA D,
           SAP_ZIEBA003 E
     WHERE     A.PARVW = 'V3'
           AND A.IMPNR = ' '
           AND B.CONNR(+) = A.CONNR
           AND B.CBTYP(+) = A.CBTYP
           AND B.CBSEQ(+) = A.CBSEQ
           AND C.CUUOM(+) = A.DEUOM
           AND D.MATNR(+) = A.MATNR
           AND E.CONNR(+) = A.CONNR
           AND E.CBTYP(+) = A.CBTYP
           AND E.CBSEQ(+) = A.CBSEQ
           AND E.MATNR(+) = A.MATNR
           AND A.ID IN (?)
      "
      records = IebMseg.find_by_sql [sql, ids[min..(max - 1)]]
      records.each do |row|
        rows.append row
      end

      if max == ids.size
        break
      else
        min = max
      end
    end

    # sql = "SELECT /*+ DRIVING_SITE(B) */
    #       A.ID, A.BUDAT, A.MJAHR, A.MBLNR, A.ZEILE, A.MATNR, A.CHARG, A.MENGE,
    #        A.MEINS, A.WRBTR, A.WAERS, A.CBSEQ, A.APMNG, B.HSTXT, C.CUTXT, A.LIFNR,
    #        (D.NETKG * MENGE) WEIGHT, A.EBELP, A.EBELN, A.CBTYP, D.MATKL, E.FSRAT
    #   FROM IEB_MSEGS A, SAP_ZIEBC001 B, SAP_ZIEBB002 C, SAP_MARA D,
    #        SAP_ZIEBA003 E
    #  WHERE     A.PARVW = 'V3'
    #        AND A.IMPNR = ' '
    #        AND B.CONNR(+) = A.CONNR
    #        AND B.CBTYP(+) = A.CBTYP
    #        AND B.CBSEQ(+) = A.CBSEQ
    #        AND C.CUUOM(+) = A.DEUOM
    #        AND D.MATNR(+) = A.MATNR
    #        AND E.CONNR(+) = A.CONNR
    #        AND E.CBTYP(+) = A.CBTYP
    #        AND E.CBSEQ(+) = A.CBSEQ
    #        AND E.MATNR(+) = A.MATNR
    #        AND A.ID IN (?)
    #   "
    # rows = IebMseg.find_by_sql [sql, ids]

    weight = 0.0
    rows.each do |row|
      row.hstxt = "Q:#{row.menge.to_f.round(3)},$:#{row.wrbtr.to_f.round(2)},D:#{row.apmng.to_f.round(3)}"
      weight = weight + row.weight.to_f.round(3)
    end

    # process row information -ve positive
    zcreate_v3_process_row(rows)

    # check negative rows
    negatives = Array.new
    rows.each do |row|
      row.wrbtr = row.wrbtr.to_f.round(2)
      row.wrbtr = 0 if (row.wrbtr.abs == 0.01)
      negatives.push("#{row.mjahr}.#{row.mblnr}.#{row.zeile}, #{row.matnr}, 項號:#{row.cbseq}, 金額:#{row.wrbtr} 是負數!!") if row.wrbtr < 0
    end
    unless negatives.empty?
      return negatives.join('\n')
    end
    #return 'tested OK'

    series = "ZTX#{Time.now.strftime('%y%m')}"
    last_val = IebSeq.next_val(series, '601')
    impnr = "#{series}#{last_val}"

    message = "進口號碼:#{impnr}交易, 已經成功導入中間庫, 等待上傳IEB, 10-15分鐘完成."

    begin
      SapSe16n.transaction do
        attributes = {
            IMPNR: impnr,
            IMTYP: 'CI',
            IMSTU: '4',
            CTLTY: 'T',
            BNAREA: Figaro.env.bnarea,
            BUKRS: Figaro.env.bukrs,
            CONNR: connr,
            LIFNR: rows.first.lifnr,
            DPSEQ: impnr.gsub('ZTX', 'ITS'),
            CUTYP: 'T',
            IMPORT: Figaro.env.bnarea,
            OEPORT: Figaro.env.bnarea,
            DLTYP: '0654',
            DUTYP: '503',
            CTTYP: '1',
            PUPOS: '05',
            DEPAT: '142',
            NDEST: '44199',
            PORTSH: '0142',
            IMDAT: Time.now.strftime('%Y%m%d'),
            PKTYP: (pktyp == '' ? '2' : pktyp),
            SATYP: '9',
            BRGEW: weight.to_f.round(3),
            NTGEW: weight.to_f.round(3),
            GEWEI: '035',
            CRDAT: Time.now.strftime('%Y%m%d'),
            CRTIME: Time.now.strftime('%H%M%S'),
            REMARK: 'IEB中間件資料導入中, 請勿打開或者修改.'
        }
        SapSe16n.create_job('ZIEBI001', 'INSERT', {}, attributes, '2')

        i = 0
        rows.each do |row|
          i = i + 1
          peinh = row.matkl[0..1] == '19' ? 10000 : 1000
          attributes = {
              IMPNR: impnr,
              IMPIM: i,
              EBELN: row.ebeln,
              EBELP: row.ebelp,
              MBLNR: row.mblnr,
              MJAHR: row.mjahr,
              ZEILE: row.zeile,
              MATNR: row.matnr,
              MENGE: row.menge.to_f.round(3),
              MEINS: row.meins,
              NETPR: (row.menge == 0 ? 0 : ((row.wrbtr.to_f * peinh) / row.menge.to_f).round(4)),
              PEINH: peinh,
              WAERS: row.waers,
              CBTYP: row.cbtyp,
              CBSEQ: row.cbseq,
              DLSEQ: row.cbseq,
              CLOSN: closn,
              CLOIM: params["cloim_#{row.id}"],
              IMPCM: params["cloim_#{row.id}"],
              NTGEW: row.weight.to_f.round(3),
              BRGEW: row.weight.to_f.round(3),
              GEWEI: 'KG',
              PKTYP: (pktyp == '' ? '2' : pktyp),
              CORIG: corig,
              DUWAY: '3',
              TXT01: row.hstxt,
              APMNG: row.apmng.to_f.round(3),
              FSMNG: (row.menge.to_f * row.fsrat.to_f).round(3),
              WRBTR: row.wrbtr.to_f.round(2)
          }
          SapSe16n.create_job('ZIEBI002', 'INSERT', {}, attributes, '2')
          IebMseg.update(row.id, {impnr: impnr})
        end
        selections = {IMPNR: impnr}
        attributes = {
            IMSTU: '1',
            REMARK: 'IEB中間件資料導入完成'
        }
        SapSe16n.create_job('ZIEBI001', 'UPDATE', selections, attributes, '2')
      end
    rescue Exception => ex
      message = "上傳失敗, 系統錯誤信息:#{ex.message}"
    end
    message
  end

  def self.zcreate_v3_process_row(rows)
    # A.ID, A.BUDAT, A.MJAHR, A.MBLNR, A.ZEILE, A.MATNR, A.CHARG, A.MENGE,
    #     A.MEINS, A.WRBTR, A.WAERS, A.CBSEQ, A.APMNG, B.HSTXT, C.CUTXT, A.LIFNR,
    #     (D.NETKG * MENGE) WEIGHT, A.EBELP, A.EBELN, A.CBTYP, D.MATKL, E.FSRAT
    negative_rows = Array.new
    positive_rows = Array.new
    rows.each do |row|
      negative_rows.append row if row.menge < 0
      positive_rows.append row if row.menge > 0
    end

    return if negative_rows.empty?

    # same lot-no, and qty and wrbtr
    negative_rows.each do |nrow|
      positive_rows.each do |prow|
        if (prow.matnr == nrow.matnr) and (prow.charg == nrow.charg) and
            (prow.menge > 0) and (nrow.menge < 0) and
            ((prow.wrbtr + nrow.wrbtr) == 0) and
            ((prow.menge + nrow.menge) == 0)
          process_nrow_prow(nrow, prow)
          break
        end
      end
    end

    # same item_no and charg but qty and wrbtr > required
    negative_rows.each do |nrow|
      positive_rows.each do |prow|
        if (prow.matnr == nrow.matnr) and (prow.charg == nrow.charg) and
            (prow.menge > 0) and (nrow.menge < 0) and
            ((prow.menge + nrow.menge) >= 0) and
            ((prow.wrbtr + nrow.wrbtr) >= 0) and
            process_nrow_prow(nrow, prow)
          break
        end
      end
    end

    # same item_no but qty and wrbtr > required
    negative_rows.each do |nrow|
      positive_rows.each do |prow|
        if (prow.matnr == nrow.matnr) and
            (prow.menge > 0) and (nrow.menge < 0) and
            ((prow.menge + nrow.menge) >= 0) and
            ((prow.wrbtr + nrow.wrbtr) >= 0) and
            process_nrow_prow(nrow, prow)
          break
        end
      end
    end

    # same lot-no, and qty
    negative_rows.each do |nrow|
      positive_rows.each do |prow|
        if (prow.matnr == nrow.matnr) and (prow.charg == nrow.charg) and
            (prow.menge > 0) and (nrow.menge < 0) and
            ((prow.menge + nrow.menge) == 0)
          process_nrow_prow(nrow, prow)
          break
        end
      end
    end

    # same lot-no
    negative_rows.each do |nrow|
      if nrow.menge < 0
        positive_rows.each do |prow|
          if (prow.matnr == nrow.matnr) and (prow.charg == nrow.charg) and
              (prow.menge > 0) and (nrow.menge < 0)
            process_nrow_prow(nrow, prow)
            break if nrow.menge >= 0
          end
        end
      end
    end

    # same material number
    negative_rows.each do |nrow|
      if nrow.menge < 0
        positive_rows.each do |prow|
          if (prow.matnr == nrow.matnr) and
              (prow.menge > 0) and (nrow.menge < 0)
            process_nrow_prow(nrow, prow)
            break if nrow.menge >= 0
          end
        end
      end
    end

    # same cbseq number
    negative_rows.each do |nrow|
      if nrow.menge < 0
        positive_rows.each do |prow|
          if (prow.cbseq == nrow.cbseq) and
              (prow.menge > 0) and (nrow.menge < 0) and
              ((prow.menge + nrow.menge) >= 0) and
              ((prow.wrbtr + nrow.wrbtr) >= 0) and
              process_nrow_prow(nrow, prow)
            break if nrow.menge >= 0
          end
        end
      end
    end

  end

  def self.process_nrow_prow(nrow, prow)
    # if prow.menge >= nrow.menge.abs and prow.wrbtr >= nrow.wrbtr.abs
    #   prow.menge = prow.menge + nrow.menge
    #   prow.wrbtr = prow.wrbtr + nrow.wrbtr
    #   prow.weight = prow.weight + nrow.weight
    #   prow.apmng = prow.apmng + nrow.apmng
    #   nrow.menge = 0
    #   nrow.wrbtr = 0
    #   nrow.weight = 0
    #   nrow.apmng = 0
    # elsif nrow.menge.abs >= prow.menge.abs and nrow.wrbtr.abs >= prow.wrbtr.abs
    #   nrow.menge = nrow.menge + prow.menge
    #   nrow.wrbtr = nrow.wrbtr + prow.wrbtr
    #   nrow.weight = nrow.weight + prow.weight
    #   nrow.apmng = nrow.apmng + prow.apmng
    #   prow.menge = 0
    #   prow.wrbtr = 0
    #   prow.weight = 0
    #   prow.apmng = 0
    # elsif prow.menge >= nrow.menge.abs and prow.wrbtr < nrow.wrbtr.abs
    #   nrow_price = (nrow.wrbtr.to_f / nrow.menge.to_f).round(2)
    #   prow_qty = (prow.menge.to_f / nrow_price).round(3)
    #   prow_qty = prow_qty.to_i if row.menge == 'EA'
    #   prow_wrbtr = (prow_qty.to_f * nrow_price.to_f).round(2)
    #   prow_weight = (nrow.weight.to_f / nrow.menge.to_f) * prow_qty
    #   prow_apmng = (nrow.apmng.to_f / nrow.menge.to_f) * prow_qty
    #   prow.menge = prow.menge - prow_qty.abs
    #   prow.wrbtr = prow.wrbtr - prow_wrbtr.abs
    #   prow.weight = prow.weight - prow_weight.abs
    #   prow.apmng = prow.apmng - prow_apmng.abs
    #   nrow.menge = nrow.menge + prow_qty.abs
    #   nrow.wrbtr = nrow.wrbtr + prow_wrbtr.abs
    #   nrow.weight = nrow.weight + prow_weight.abs
    #   nrow.apmng = nrow.apmng + prow_apmng.abs
    # end
    if prow.menge >= nrow.menge.abs
      prow.menge = prow.menge + nrow.menge
      prow.wrbtr = prow.wrbtr + nrow.wrbtr
      prow.weight = prow.weight + nrow.weight
      prow.apmng = prow.apmng + nrow.apmng
      nrow.menge = 0
      nrow.wrbtr = 0
      nrow.weight = 0
      nrow.apmng = 0
    else
      nrow.menge = nrow.menge + prow.menge
      nrow.wrbtr = nrow.wrbtr + prow.wrbtr
      nrow.weight = nrow.weight + prow.weight
      nrow.apmng = nrow.apmng + prow.apmng
      prow.menge = 0
      prow.wrbtr = 0
      prow.weight = 0
      prow.apmng = 0

    end
  end

end
