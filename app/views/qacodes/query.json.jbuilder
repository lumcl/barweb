json.array!(@qacode) do |row|
  json.extract! row, :id, :qrcode, :aufnr, :matnr, :cycle
  json.url row_url(row, format: :json)
end
