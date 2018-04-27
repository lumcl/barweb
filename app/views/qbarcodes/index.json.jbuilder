json.array!(@qbarcodes) do |qbarcode|
  json.extract! qbarcode, :id, :qrcode, :aufnr, :matnr, :muser
  json.url qbarcodes_url(qbarcode, format: :json)
end
