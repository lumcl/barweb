class YgtPreEms3Img < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :ems_no, :g_no
  self.table_name = 'sap.pre_ems3_img'

end