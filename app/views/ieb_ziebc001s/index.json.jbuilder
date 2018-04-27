json.array!(@ieb_ziebc001s) do |ieb_ziebc001|
  json.extract! ieb_ziebc001, :id, :connr, :cbtyp, :cbseq, :hstxt, :smode, :deuom, :fsuom, :rstat
  json.url ieb_ziebc001_url(ieb_ziebc001, format: :json)
end
