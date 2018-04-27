class YgtErpBillList < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :op_no, :list_g_no
  self.table_name = 'sap.erp_bill_list'

end
