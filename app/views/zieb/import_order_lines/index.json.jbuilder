json.array!(@zieb_import_order_lines) do |zieb_import_order_line|
  json.extract! zieb_import_order_line, :id, :zieb_import_order_id, :mandt, :order_no, :seq, :lifnr, :name1, :lifdn, :lifdn_date, :ebeln, :ebelp, :etens, :matnr, :txz01, :werks, :waers, :netpr, :meins, :xblnr, :menge, :amount, :cbtyp, :cbseq, :hstxt, :dlrat, :dlqty, :ntgew, :brgew, :corig, :pktyp, :pkqty, :pkuom, :brand, :part_no, :created_by, :updated_by
  json.url zieb_import_order_line_url(zieb_import_order_line, format: :json)
end
