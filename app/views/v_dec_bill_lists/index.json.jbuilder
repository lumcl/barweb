json.array!(@v_dec_bill_lists) do |v_dec_bill_list|
  json.extract! v_dec_bill_list, :id
  json.url v_dec_bill_list_url(v_dec_bill_list, format: :json)
end
