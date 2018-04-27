json.array!(@ieb_zieba003s) do |ieb_zieba003|
  json.extract! ieb_zieba003, :id, :connr, :matnr, :cbtyp, :cbseq, :dlrat, :fsrat, :rstat
  json.url ieb_zieba003_url(ieb_zieba003, format: :json)
end
