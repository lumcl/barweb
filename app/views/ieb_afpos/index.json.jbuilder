json.array!(@ieb_afpos) do |ieb_afpo|
  json.extract! ieb_afpo, :id, :aufnr, :matnr, :bom_id, :psmng, :wemng, :apmng, :received, :received_at, :declared, :declared_at, :finished, :finished_at, :analysed, :analysed_at, :sap_updated, :sap_updated_at
  json.url ieb_afpo_url(ieb_afpo, format: :json)
end
