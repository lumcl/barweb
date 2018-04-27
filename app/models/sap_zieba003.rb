class SapZieba003 < ActiveRecord::Base
  self.primary_keys = :connr, :matnr
  self.table_name = 'sap_zieba003'

  belongs_to :matnr_obj, class_name: 'SapMara', foreign_key: :matnr
  belongs_to :connr_obj, class_name: 'SapZiebc001', foreign_key: [:connr, :cbtyp, :cbseq]


  def self.update_dlseq
    sql = "
        SELECT MATNR,CBSEQ,DLSEQ FROM SAPSR3.ZIEBA003
        WHERE CBSEQ <> DLSEQ
        AND MANDT='168' AND BNAREA='5207' AND BUKRS='L300' AND CONNR='E52070000001'
        AND CBSEQ <> '0000' AND DLSEQ = '0000'
    "
    list = Sapdb.find_by_sql sql

    list.each do |row|
      SapSe16n.transaction do
        selections = {BNAREA: '5207', BUKRS: 'L300', CONNR: 'E52070000001', MATNR: row.matnr}
        attributes = {DLSEQ: row.cbseq}
        SapSe16n.create_job('ZIEBA003', 'UPDATE', selections, attributes, '2')
      end
    end

  end

end
