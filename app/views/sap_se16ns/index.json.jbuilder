json.array!(@sap_se16ns) do |sap_se16n|
  json.extract! sap_se16n, :id, :status, :table_name, :action_type, :selection_keys, :selection_values, :attribute_keys, :attribute_values, :error_msg, :updated_ip, :sap_updated_at
  json.url sap_se16n_url(sap_se16n, format: :json)
end
