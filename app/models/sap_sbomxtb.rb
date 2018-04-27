class SapSbomxtb < ActiveRecord::Base
  self.table_name = 'sap_sbomxtb'

  belongs_to :pmatnr_obj, class_name: 'SapMara', foreign_key: 'pmatnr'
  belongs_to :cmatnr_obj, class_name: 'SapMara', foreign_key: 'cmatnr'
end
