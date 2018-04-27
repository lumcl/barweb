class Zieb::ImportOrder < ActiveRecord::Base
  validates_presence_of :order_no, :order_date, :import_date, :connr
  validates_uniqueness_of :order_no
  validate :check_lifnr

  before_create :z_before_create

  has_many :zieb_import_order_lines, :class_name => 'Zieb::ImportOrderLine', foreign_key: 'zieb_import_order_id', dependent: :destroy

  def check_lifnr
    rows = Sql.find_by_sql ['select name1 from sapsr3.lfa1@sapp where mandt=? and lifnr=?', Figaro.env.mandt, lifnr]
    if rows.length == 0
      errors.add(:lifnr, '供應商代碼不存在')
    else
      self.name1 = rows.first.name1
    end
  end

  def status
    if elikz == 'X'
      '完成'
    else
      '維護中'
    end
  end

  def z_before_create
    self.order_no = order_no.strip.upcase
    self.mandt = Figaro.env.mandt
    ziebr005 = Sql.find_by_sql ['select * from sapsr3.ziebr005@sapp where mandt=? and connr=?', Figaro.env.mandt, connr]
    self.bnarea = ziebr005.first.bnarea
    self.bukrs = ziebr005.first.bukrs
  end


end
