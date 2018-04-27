json.array!(@ieb_seqs) do |ieb_seq|
  json.extract! ieb_seq, :id, :seq, :lastval
  json.url ieb_seq_url(ieb_seq, format: :json)
end
