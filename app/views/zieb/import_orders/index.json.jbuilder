json.array!(@zieb_import_orders) do |zieb_import_order|
  json.extract! zieb_import_order, :id, :mandt, :order_no, :order_date, :order_type, :import_date, :bnarea, :bukrs, :connr, :parvw, :dlfnr, :zterm, :created_by, :updated_by
  json.url zieb_import_order_url(zieb_import_order, format: :json)
end
