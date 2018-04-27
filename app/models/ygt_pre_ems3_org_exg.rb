class YgtPreEms3OrgExg < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :ems_no, :cop_g_no
  self.table_name = 'sap.pre_ems3_org_exg'
end
