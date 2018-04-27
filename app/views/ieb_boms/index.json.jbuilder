json.array!(@ieb_boms) do |ieb_bom|
  json.extract! ieb_bom, :id, :connr, :matnr, :vernr, :rstat, :menge, :sap_updated, :sap_updated_at, :ygt_updated, :ygt_updated_at, :home_made_parts
  json.url ieb_bom_url(ieb_bom, format: :json)
end
