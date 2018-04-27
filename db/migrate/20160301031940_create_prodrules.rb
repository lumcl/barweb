class CreateProdrules < ActiveRecord::Migration
  def change
    create_table :prodrules do |t|
      t.string :qrcode
      t.string :rule
      t.string :matnr
      t.string :muser

      t.timestamps
    end
    add_index :prodrules, :qrcode
  end
end
