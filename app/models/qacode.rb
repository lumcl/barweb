class Qacode < ActiveRecord::Base
  self.table_name = 'qacodes'
  #validates_uniqueness_of :qrcode, :cycle
end
