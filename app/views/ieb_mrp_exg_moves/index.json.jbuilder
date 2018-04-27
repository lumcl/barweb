json.array!(@ieb_mrp_exg_moves) do |ieb_mrp_exg_move|
  json.extract! ieb_mrp_exg_move, :id, :budat, :mjahr, :mblnr, :zeile, :matnr, :maktx, :menge, :meins, :charg, :vbeln, :posnr, :vgbel, :vgpos, :bednr, :auart, :bill_to, :ship_to, :name1, :aufnr, :ntgew, :brgew, :gewei, :status, :created_by, :updated_by, :created_ip, :updated_ip
  json.url ieb_mrp_exg_move_url(ieb_mrp_exg_move, format: :json)
end
