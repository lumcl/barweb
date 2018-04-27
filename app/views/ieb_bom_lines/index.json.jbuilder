json.array!(@ieb_bom_lines) do |ieb_bom_line|
  json.extract! ieb_bom_line, :id, :bom_id, :idnrk, :werks, :menge, :ausch, :apmng, :bond, :dpmatnr
  json.url ieb_bom_line_url(ieb_bom_line, format: :json)
end
