class SapZiebc001 < ActiveRecord::Base
  self.primary_keys = :connr, :cbtyp, :cbseq
  self.table_name = 'sap_ziebc001'

  belongs_to :deuom_obj, class_name: 'SapZiebb002', foreign_key: 'deuom'
  belongs_to :fsuom_obj, class_name: 'SapZiebb002', foreign_key: 'fsuom'
end
