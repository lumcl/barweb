class IebZiebc001 < ActiveRecord::Base

  def self.get_rstat_eq_1(connr,crdat)
    sql = "SELECT CONNR,CBTYP,CBSEQ,HSCODE,HSTXT,SMODE,DEUOM,FSUOM, CBSTA RSTAT FROM SAPSR3.ZIEBC001
        WHERE MANDT='168' AND BNAREA=? AND BUKRS=? AND CONNR=? AND CBTYP='R' AND CRDAT = ? ORDER BY CBSEQ"
    list = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr, crdat]
    cbseqs = Array.new
    list.each do |row|
      cbseqs.append row.cbseq
    end

    ieb_cbseqs = Array.new
    ziebc001s = IebZiebc001.select(:cbseq).where(cbtyp: 'R').where(cbseq: cbseqs)
    ziebc001s.each do |row|
      ieb_cbseqs.append row.cbseq
    end

    rows = Array.new
    list.each do |row|
      rows.append row unless ieb_cbseqs.include?(row.cbseq)
    end

    sql = "SELECT CONNR,CBTYP,CBSEQ,HSCODE,HSTXT,SMODE,DEUOM,FSUOM, CBSTA RSTAT FROM SAPSR3.ZIEBC001
        WHERE MANDT='168' AND BNAREA=? AND BUKRS=? AND CONNR=? AND CBTYP='F' AND CRDAT = ? ORDER BY CBSEQ"
    list = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr, crdat]
    cbseqs = Array.new
    list.each do |row|
      cbseqs.append row.cbseq
    end

    ieb_cbseqs = Array.new
    ziebc001s = IebZiebc001.select(:cbseq).where(cbtyp: 'F').where(cbseq: cbseqs)
    ziebc001s.each do |row|
      ieb_cbseqs.append row.cbseq
    end

    list.each do |row|
      rows.append row unless ieb_cbseqs.include?(row.cbseq)
    end

    return rows
  end

  def self.upload_ygt(connr, keys)
    notice = I18n.t('upload_success')
    cbseqs = Array.new
    keys.each do |key|
      buf = key.split('|')
      cbseqs.append buf[1] if buf[0] == 'R'
    end
    sql = "SELECT CONNR,CBTYP,CBSEQ,HSCODE,HSTXT, SUBSTR ( SMODE, 1, 50) SMODE,DEUOM,FSUOM, CBSTA RSTAT FROM SAPSR3.ZIEBC001
        WHERE MANDT='168' AND BNAREA=? AND BUKRS=? AND CONNR=? AND CBTYP='R' AND CBSEQ IN (?) ORDER BY CBSEQ"
    rows = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr, cbseqs]
    unless rows.empty?
      begin
        YgtPreEms3Img.transaction do
          IebZiebc001.transaction do
            SapSe16n.transaction do
              rows.each do |row|
                YgtPreEms3Img.create!({
                                          ems_no: connr,
                                          code_t_s: row.hscode,
                                          g_no: row.cbseq,
                                          g_name: row.hstxt,
                                          unit: row.deuom,
                                          unit_1: row.fsuom,
                                          g_model: row.smode
                                      })
                IebZiebc001.create!({
                                        cbseq: row.cbseq,
                                        cbtyp: row.cbtyp,
                                        connr: connr,
                                        deuom: row.deuom,
                                        fsuom: row.fsuom,
                                        hstxt: row.hstxt,
                                        hscode: row.hscode,
                                        smode: row.smode,
                                        rstat: '2'
                                    })

                # selections = {
                #     BNAREA: Figaro.env.bnarea,
                #     BUKRS: Figaro.env.bukrs,
                #     CONNR: connr,
                #     CBTYP: row.cbtyp,
                #     CBSEQ: row.cbseq
                # }
                # attributes = {CBSTA: '2'}
                #SapSe16n.create_transaction('ZIEBC001', 'UPDATE', selections, attributes)
              end
            end
          end
        end

      rescue Exception => ex
        puts ex.message
      end
    end
    # handling finish goods

    cbseqs = Array.new
    keys.each do |key|
      buf = key.split('|')
      cbseqs.append buf[1] if buf[0] == 'F'
    end
    sql = "SELECT CONNR,CBTYP,CBSEQ,HSCODE,HSTXT, SUBSTR ( SMODE, 1, 50) SMODE,DEUOM,FSUOM, CBSTA RSTAT FROM SAPSR3.ZIEBC001
        WHERE MANDT='168' AND BNAREA=? AND BUKRS=? AND CONNR=? AND CBTYP='F' AND CBSEQ IN (?) ORDER BY CBSEQ"
    rows = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr, cbseqs]
    unless rows.empty?
      begin
        YgtPreEms3Exg.transaction do
          IebZiebc001.transaction do
            SapSe16n.transaction do
              rows.each do |row|
                YgtPreEms3Exg.create!({
                                          ems_no: connr,
                                          code_t_s: row.hscode,
                                          g_no: row.cbseq,
                                          g_name: row.hstxt,
                                          unit: row.deuom,
                                          unit_1: row.fsuom,
                                          g_model: row.smode
                                      })
                IebZiebc001.create!({
                                        cbseq: row.cbseq,
                                        cbtyp: row.cbtyp,
                                        connr: connr,
                                        deuom: row.deuom,
                                        fsuom: row.fsuom,
                                        hstxt: row.hstxt,
                                        hscode: row.hscode,
                                        smode: row.smode,
                                        rstat: '2'
                                    })

                # selections = {
                #     BNAREA: Figaro.env.bnarea,
                #     BUKRS: Figaro.env.bukrs,
                #     CONNR: connr,
                #     CBTYP: row.cbtyp,
                #     CBSEQ: row.cbseq
                # }
                # attributes = {CBSTA: '2'}
                # SapSe16n.create_transaction('ZIEBC001', 'UPDATE', selections, attributes)
              end
            end
          end
        end
      rescue Exception => ex
        puts ex.message
      end
    end

    return notice
  end

end
