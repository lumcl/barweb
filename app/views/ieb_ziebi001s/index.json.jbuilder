json.array!(@ieb_ziebi001s) do |ieb_ziebi001|
  json.extract! ieb_ziebi001, :id, :impnr, :imtyp, :imstu, :imdat, :dlfnr, :decdt, :created_by, :updated_by
  json.url ieb_ziebi001_url(ieb_ziebi001, format: :json)
end
