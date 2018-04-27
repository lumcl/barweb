class YgtPreEms3OrgBom < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :ems_no, :cop_exg_no, :cop_img_no, :begin_date
  self.table_name = 'sap.pre_ems3_org_bom'

  def self.upload_boms(bom_id)
    ieb_bom = IebBom.find(bom_id)
    notice = I18n.t('upload_success')
    begin
      sql = 'SELECT ID,CONNR,MATNR,VERNR,IDNRK,WERKS,MENGE,MEINS,AUSCH,DLRAT,DEUOM,CUTXT,NETKG,CBTYP,CBSEQ,HSCODE,HSTXT,MATKL,MAKTX FROM IEB_BOMS_V1 WHERE ID = ? AND WERKS IN (?)'
      rows = IebBom.find_by_sql [sql, bom_id, '381A']

      YgtPreEms3OrgBom.transaction do
        rows.each do |row|
          YgtPreEms3OrgBom.create({ems_no: row.connr,
                                   cop_exg_no: row.matnr,
                                   cop_img_no: row.idnrk,
                                   begin_date: row.vernr,
                                   dec_cm: (row.menge * row.dlrat).round(9),
                                   dec_dm: (row.ausch || 0),
                                   ent_dec_cm: row.menge,
                                   ent_dec_dm: (row.ausch || 0)
                                  })
        end

        unless rows.empty?
          IebBom.transaction do
            zieba003 = SapZieba003.where(connr: ieb_bom.connr).where(matnr: ieb_bom.matnr).first
            attributes = {
                BNAREA: Figaro.env.bnarea,
                BUKRS: Figaro.env.bukrs,
                CONNR: zieba003.connr,
                CBTYP: zieba003.cbtyp,
                CBSEQ: zieba003.cbseq,
                DLSEQ: zieba003.cbseq,
                VERNR: ieb_bom.vernr,
                RSTAT: '1',
                DATUV: Time.now.strftime('%Y%m%d'),
                MATNR: zieba003.matnr,
                CRDAT: Time.now.strftime('%Y%m%d'),
                CRNAM: 'LUM.LIN'
            }
            SapSe16n.create_transaction('ZIEBA001', 'INSERT', {}, attributes)

            rows.each do |row|
              attributes = {
                  BNAREA: Figaro.env.bnarea,
                  BUKRS: Figaro.env.bukrs,
                  CONNR: row.connr,
                  CBTYP: zieba003.cbtyp,
                  CBSEQ: zieba003.cbseq,
                  DLSEQ: zieba003.cbseq,
                  VERNR: row.vernr,
                  IDNRK: row.idnrk,
                  MNGKO: row.menge,
                  MEINS: row.meins,
                  MENGE: (row.menge * row.dlrat).round(9),
                  DEUOM: row.deuom,
                  AUSCH: (row.ausch || 0),
                  CBTYP_R: row.cbtyp,
                  CBSEQ_R: row.cbseq,
                  BOND: 'X',
                  CRDAT: Time.now.strftime('%Y%m%d'),
                  CRNAM: 'LUM.LIN'
              }
              SapSe16n.create_transaction('ZIEBA002', 'INSERT', {}, attributes)
            end

            sql = 'SELECT CONNR,VERNR,DEUOM,AUSCH,CBTYP,CBSEQ,SUM(MENGE*DLRAT) MENGE FROM IEB_BOMS_V1 WHERE ID = ? AND WERKS IN (?) GROUP BY CONNR,VERNR,DEUOM,AUSCH,CBTYP,CBSEQ'
            xrows = IebBom.find_by_sql [sql, bom_id, '381A']
            xrows.each do |row|
              attributes = {
                  BNAREA: Figaro.env.bnarea,
                  BUKRS: Figaro.env.bukrs,
                  CONNR: row.connr,
                  CBTYP: zieba003.cbtyp,
                  CBSEQ: zieba003.cbseq,
                  DLSEQ: zieba003.cbseq,
                  VERNR: row.vernr,
                  CBTYP_R: row.cbtyp,
                  CBSEQ_R: row.cbseq,
                  MENGE: row.menge.round(9),
                  DEUOM: row.deuom,
                  AUSCH: row.ausch,
                  CRDAT: Time.now.strftime('%Y%m%d'),
                  CRNAM: 'LUM.LIN'
              }
              SapSe16n.create_transaction('ZIEBA004', 'INSERT', {}, attributes)
            end
            ieb_bom.rstat = '2'
            ieb_bom.ygt_updated = true
            ieb_bom.ygt_updated_at = Time.now
            ieb_bom.save
          end
        end
      end
    rescue Exception => ex
      notice = ex.message
    end
    return "#{ieb_bom.matnr}[#{ieb_bom.vernr}] #{notice}"
  end

end
