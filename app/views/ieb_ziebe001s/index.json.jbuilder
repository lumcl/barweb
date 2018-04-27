json.array!(@ieb_ziebe001s) do |ieb_ziebe001|
  json.extract! ieb_ziebe001, :id, :expnr, :extyp, :exstu, :expdat, :dlfnr, :decdt, :created_by, :updated_by
  json.url ieb_ziebe001_url(ieb_ziebe001, format: :json)
end
