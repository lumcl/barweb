class YgtPreEms3OrgBomState < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :ems_no, :cop_exg_no, :cop_img_no, :begin_date
  self.table_name = 'sap.pre_ems3_org_bom_state'

  def self.update_sap
    sql = 'SELECT DISTINCT EMS_NO, COP_EXG_NO,BEGIN_DATE FROM PRE_EMS3_ORG_BOM_STATE WHERE RSTAT = 1'
    rows = YgtPreEms3OrgBomState.find_by_sql sql
    SapSe16n.transaction do
      YgtPreEms3OrgBomState.transaction do
        IebBom.transaction do
          rows.each do |row|
            IebBom.where(connr: row.ems_no)
                .where(matnr: row.cop_exg_no)
                .where(vernr: row.begin_date)
                .update_all(rstat: '3')
            selections = {
                BNAREA: Figaro.env.bnarea,
                BUKRS: Figaro.env.bukrs,
                CONNR: row.ems_no,
                MATNR: row.cop_exg_no,
                VERNR: row.begin_date
            }
            attributes = {RSTAT: '3'}
            SapSe16n.create_job('ZIEBA001', 'UPDATE', selections, attributes,'4')
            YgtPreEms3OrgBomState.where(ems_no: row.ems_no)
                .where(cop_exg_no: row.cop_exg_no)
                .where(begin_date: row.begin_date)
                .update_all(rstat: '3')
          end
        end
      end
    end
  end

end