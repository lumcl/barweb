json.array!(@pcbmains) do |pcbmain|
  json.extract! pcbmain, :id, :id, :pcblabel, :panellabel, :clientip
  json.url pcbmain_url(pcbmain, format: :json)
end
