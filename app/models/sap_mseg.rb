class SapMseg < ActiveRecord::Base
  self.primary_keys = :mblnr, :mjahr, :zeile
  self.table_name = 'sap_mseg'
end