class IebZieba003 < ActiveRecord::Base


  def self.not_reported_materials(connr)
    sql = "SELECT A.CONNR, A.CBTYP, A.CBSEQ, A.MATNR, A.DLRAT, A.FSRAT, A.RSTAT, B.MATKL,
           B.MAKTX, B.MEINS, DECODE (B.GEWEI, 'G', B.NTGEW / 1000, B.NTGEW) NETKG,
           C.HSCODE, C.HSTXT, C.DEUOM, D.CUTXT, A.ROWID RID
      FROM SAPSR3.ZIEBA003 A, SAPSR3.MARAV B, SAPSR3.ZIEBC001 C, SAPSR3.ZIEBB002 D
     WHERE     A.MANDT = '168'
           AND A.BNAREA = ?
           AND A.BUKRS = ?
           AND A.CONNR = ?
           AND A.BLOCK = ' '
           AND NVL(A.CBSEQ,'0000') <> '0000'
           AND A.RSTAT = '1'
           AND B.MANDT = A.MANDT
           AND B.MATNR = A.MATNR
           AND B.SPRAS = 'M'
           AND C.MANDT = A.MANDT
           AND C.BNAREA = A.BNAREA
           AND C.BUKRS = A.BUKRS
           AND C.CONNR = A.CONNR
           AND C.CBTYP = A.CBTYP
           AND C.CBSEQ = A.CBSEQ
           AND D.MANDT = C.MANDT
           AND D.CUUOM = C.DEUOM"
    list = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr]
    matnrs = Array.new
    list.each do |row|
      matnrs.append row.matnr
    end

    ieb_matnrs = Array.new
    zieba003s = IebZieba003.select(:matnr).where(matnr: matnrs).where(connr: connr)
    zieba003s.each do |row|
      ieb_matnrs.append row.matnr
    end

    rows = Array.new
    list.each do |row|
      rows.append row unless ieb_matnrs.include?(row.matnr)
    end

    return rows
  end

  def self.upload_ygt(connr, matnrs)
    notice = I18n.t('upload_success')
    success_matnrs = Array.new

    sql ="SELECT A.CONNR, A.MATNR, A.CBSEQ, B.MEINS, DLRAT, FSRAT, A.CBTYP,
          DECODE (B.GEWEI, 'G', B.NTGEW / 1000, B.NTGEW) NETKG, C.MAKTX, B.MATKL
     FROM SAPSR3.ZIEBA003 A, SAPSR3.MARA B, SAPSR3.MAKT C
    WHERE     A.MANDT = '168'
          AND A.BNAREA = ?
          AND A.BUKRS = ?
          AND A.CONNR = ?
          AND B.MANDT = '168'
          AND A.BLOCK = ' '
          AND B.MATNR = A.MATNR
          AND C.MANDT = '168'
          AND C.MATNR = A.MATNR
          AND C.SPRAS = 'M'
          AND A.MATNR IN (?)"
    rows = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr, matnrs]
    begin
      YgtPreEms3OrgImg.transaction do
        IebZieba003.transaction do
          rows.each do |row|
            if row.cbtyp == 'R'
              YgtPreEms3OrgImg.create!({
                                           ems_no: connr,
                                           cop_g_no: row.matnr,
                                           g_no: row.cbseq,
                                           g_model: row.maktx,
                                           g_eng_name: row.maktx,
                                           ent_unit: row.meins,
                                           curr: '502',
                                           unit_ratio: row.dlrat.round(7),
                                           factor_1: row.fsrat.round(9),
                                           factor_wt: row.netkg.round(9),
                                           note: row.matkl
                                       })
            else
              YgtPreEms3OrgExg.create!({
                                           ems_no: connr,
                                           cop_g_no: row.matnr,
                                           g_no: row.cbseq,
                                           g_model: row.maktx,
                                           g_eng_name: row.maktx,
                                           ent_unit: row.meins,
                                           curr: '502',
                                           unit_ratio: row.dlrat.round(7),
                                           factor_1: row.fsrat.round(9),
                                           factor_wt: row.netkg.round(9),
                                           note: row.matkl
                                       })
            end
            IebZieba003.create!({
                                    cbseq: row.cbseq,
                                    cbtyp: row.cbtyp,
                                    connr: row.connr,
                                    dlrat: row.dlrat,
                                    fsrat: row.fsrat,
                                    matnr: row.matnr,
                                    rstat: '2'
                                })

            selections = {
                BNAREA: Figaro.env.bnarea,
                BUKRS: Figaro.env.bukrs,
                CONNR: row.connr,
                MATNR: row.matnr,
                CBTYP: row.cbtyp,
                CBSEQ: row.cbseq
            }

            attributes = {RSTAT: '2'}

            SapSe16n.create_transaction('ZIEBA003', 'UPDATE', selections, attributes)
            success_matnrs.append row.matnr
          end
        end
      end
    rescue Exception => ex
      notice = ex.message
    end
    return "#{success_matnrs.join(',')} #{notice}"
  end

end
