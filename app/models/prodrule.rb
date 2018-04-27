class Prodrule < ActiveRecord::Base
  self.table_name = 'prodrules'
  validates_uniqueness_of :matnr
end
