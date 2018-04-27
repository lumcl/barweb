json.array!(@prodrules) do |prodrule|
  json.extract! prodrule, :id, :qrcode, :rule, :matnr, :muser
  json.url prodrule_url(prodrule, format: :json)
end
