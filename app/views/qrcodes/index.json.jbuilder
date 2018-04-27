json.array!(@qrcodes) do |qrcode|
  json.extract! qrcode, :id, :qrcode, :aufnr, :matnr, :muser
  json.url qrcode_url(qrcode, format: :json)
end
