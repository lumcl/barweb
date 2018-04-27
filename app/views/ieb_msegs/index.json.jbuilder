json.array!(@ieb_msegs) do |ieb_mseg|
  json.extract! ieb_mseg, :id, :mjahr, :mblnr, :zeile, :vgart, :blart, :bwart, :budat, :cpudt, :cputm, :matnr, :werks, :lgort, :charg, :menge, :meins, :dmbtr, :waers, :parvw, :lifnr, :ebeln, :ebelp, :xblnr, :belnr_ap, :buzei_ap, :gjahr_ap, :guinr, :lifnr_sto, :ebeln_sto, :ebelp_sto, :belnr_sto, :buzei_sto, :gjahr_sto, :kunnr, :kunnr_dlv, :vbeln_dn, :posnr_dn, :vbeln_so, :posnr_so, :vbeln_inv, :posnr_inv, :aufnr, :rsnum, :rspos, :connr, :cbseq, :apmng, :dlrat, :cutxt, :impnr, :impim, :expnr, :expim, :dlfnr, :decdt, :belnr_pay, :buzei_pay, :gjahr_pay, :rstat
  json.url ieb_mseg_url(ieb_mseg, format: :json)
end
