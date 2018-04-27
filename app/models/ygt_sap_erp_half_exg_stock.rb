class YgtSapErpHalfExgStock < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :kucun_date, :wh_no, :item_no, :pici_no
  self.table_name = 'sap.sap_erp_halfexg_stock'


end