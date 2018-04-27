json.array!(@zmm_item_suppliers) do |zmm_item_supplier|
  json.extract! zmm_item_supplier, :id
  json.url zmm_item_supplier_url(zmm_item_supplier, format: :json)
end
