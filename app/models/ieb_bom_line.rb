class IebBomLine < ActiveRecord::Base
  belongs_to :ieb_bom, class_name: 'IebBom', foreign_key: 'ieb_bom_id'
end
