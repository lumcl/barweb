json.array!(@ieb_erp_stocks) do |ieb_erp_stock|
  json.extract! ieb_erp_stock, :id, :stkdate, :matnr, :lgort, :charg, :balqty, :meins, :ebeln, :ebelp, :aufnr, :matkl, :mtart, :maktx, :dlrat, :deuom, :hstxt, :cbtyp
  json.url ieb_erp_stock_url(ieb_erp_stock, format: :json)
end
