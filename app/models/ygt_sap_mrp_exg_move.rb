class YgtSapMrpExgMove < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :dn_no, :dn_id
  self.table_name = 'sap.sap_mrp_exg_move'

  def self.insert_record
    sql = "
      select c.vernr,b.ieb_bom_id,a.*
        from ieb_mrp_exg_moves a
          join ieb_afpos b on b.aufnr=a.aufnr
          join ieb_boms c on c.id = b.ieb_bom_id
        where auart='ZC4' and status = '10'
    "
    list = IebMrpExgMove.find_by_sql sql
    list.each do |row|
      YgtSapMrpExgMove.transaction do
        IebMrpExgMove.transaction do

          YgtSapMrpExgMove.create(
              {
                  dn_no: row.vbeln,
                  dn_id: row.posnr,
                  document_no: "SO:#{row.bednr}.#{row.afnam}",
                  document_date: row.budat,
                  document_id: row.id,
                  batch_no: row.charg,
                  customer_code: row.ship_to,
                  customer_name: row.name1,
                  item_no: row.matnr,
                  item_depict: row.maktx,
                  post_date: row.budat,
                  qty: row.menge,
                  unit: row.meins,
                  wo_no: row.aufnr,
                  exg_version: row.vernr,
                  goss_wt: row.brgew.round(5),
                  wet_wt: row.ntgew.round(5),
                  note: "MB:#{row.mjahr}.#{row.mblnr}.#{row.zeile}|STO:#{row.vgbel}.#{row.vgpos}",
                  pak_qty: 0,
                  dec_price: row.netpr.round(5),
                  factor_1: 0,
                  factor_2: 0,
                  inv_no: row.vbeln,
                  curr: row.waers,
                  customer_g_no: row.kdmat
              }
          )
          IebMrpExgMove.update(row.id, status: '20')
        end
      end
    end
  end

end