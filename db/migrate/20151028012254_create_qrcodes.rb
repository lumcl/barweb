class CreateQrcodes < ActiveRecord::Migration
  def change
    create_table :qrcode do |t|
      t.string :qrcode
      t.string :aufnr
      t.string :matnr
      t.string :muser
      t.timestamps
    end
    add_index :qrcode, :qrcode
  end
end
