json.array!(@qacodes) do |qacode|
  json.extract! qacode, :id, :id, :qrcode, :aufnr, :matnr, :muser, :cycle
  json.url qacode_url(qacode, format: :json)
end
