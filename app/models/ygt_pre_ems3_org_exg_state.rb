class YgtPreEms3OrgExgState < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :ems_no, :cop_g_no
  self.table_name = 'sap.pre_ems3_org_exg_state'

  def self.upload_sap
    rows = YgtPreEms3OrgExgState.where(rstat: '1')
    YgtPreEms3OrgExgState.transaction do
      SapSe16n.transaction do
        rows.each do |row|
          dlseq = '0000'
          sql = "select cbseq from sapsr3.zieba003 where mandt='168' and bnarea=? and bukrs=? and connr=? and matnr=?"
          records = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, row.ems_no, row.cop_g_no]
          records.each do |r|
            dlseq = r.cbseq
          end
          selections = {
              BNAREA: Figaro.env.bnarea,
              BUKRS: Figaro.env.bukrs,
              CONNR: row.ems_no,
              MATNR: row.cop_g_no
          }
          attributes = {RSTAT: '3', DLSEQ: dlseq}
          SapSe16n.create_transaction('ZIEBA003', 'UPDATE', selections, attributes)

          a003 = IebZieba003.where(connr: row.ems_no).where(matnr: row.cop_g_no).first
          if a003
            a003.rstat = '3'
            a003.save!
          end
          row.rstat = '3'
          row.save!
        end
      end
    end
  end

end
