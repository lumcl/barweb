class Qbarcode < ActiveRecord::Base
  self.table_name = 'qbarcodes'
  #validates_uniqueness_of :qbarcodes
end
