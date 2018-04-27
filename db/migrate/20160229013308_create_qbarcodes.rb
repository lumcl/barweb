class CreateQbarcodes < ActiveRecord::Migration
  def change
    create_table :qbarcodes do |t|
      t.string :qrcode
      t.string :aufnr
      t.string :matnr
      t.string :muser
      t.string :rule
      t.string :same

      t.timestamps
    end
  end
end
