class Qrcode < ActiveRecord::Base
  self.table_name = 'qrcode'
  validates_uniqueness_of :qrcode
end
