class Zmm::ItemSupplier < ActiveRecord::Base
  before_save :z_before_save

  def status
    if elikz == 'X'
      '完成'
    else
      '維護中'
    end
  end

  def z_before_save
    if corig_changed?
      if corig == ''
        self.cktxt = ''
      else
        list = Sql.find_by_sql ["select cktxt from sapsr3.ziebb012@sapp where mandt = ? and cland = ?", Figaro.env.mandt, corig]
        self.cktxt = list.first.cktxt
      end
    end
  end

end
