class Sapco < ActiveRecord::Base
  establish_connection :sapco
  self.primary_key = 'rid'
  self.table_name = 'it.tlog'

  def self.ztest
    Sapco.create({
                     objname: 'Crontest',
                     updtime: Time.now.strftime('%Y%m%d:%H%M%S')
                 })
  end
end