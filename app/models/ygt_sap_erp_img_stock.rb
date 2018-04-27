class YgtSapErpImgStock < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_keys = :kucun_date, :wh_no, :wh_loc, :item_no, :pici_no
  self.table_name = 'sap.sap_erp_img_stock'


  # READ_ZROH_STK_SQL =
  # "
  #   select matnr,werks,lgort,onhand,lfgja,lfmon,nvl(pqty,onhand)pqty,rank,meins,maktx
  # from
  #   (select b.matnr,b.werks,b.lgort,(b.labst + b.umlme + b.insme + b.einme + b.speme + b.retme) onhand,
  #          c.lfgja,c.lfmon,(c.labst + c.umlme + c.insme + c.einme + c.speme + c.retme)pqty,
  #          a.meins,t.maktx,
  #          rank() over  (partition by b.matnr,b.werks,b.lgort order by c.lfgja,c.lfmon) rank
  #     from sapsr3.mara a
  #       join sapsr3.mard b on b.mandt=a.mandt and b.matnr=a.matnr and b.werks=?
  #       left join sapsr3.makt t on t.mandt=a.mandt and t.matnr=a.matnr and t.spras='M'
  #       left join sapsr3.mardh c on c.mandt=b.mandt and c.matnr=b.matnr and c.lgort=b.lgort
  #                                and (( c.lfgja = ? and c.lfmon >= ? ) or c.lfgja > ? )
  #     where a.mandt='168' and a.mtart = 'ZROH'
  #     order by b.matnr,b.werks,b.lgort,c.lfgja,c.lfmon)
  #  where rank = 1 and nvl(pqty,onhand) > 0
  # "
  #
  # def self.insert_zroh_stock(year, month, werks)
  #   kucun_date = Date.new(year.to_i, month.to_i, -1)
  #   kucun_date = Time.now.to_date if kucun_date > Time.now.to_date
  #   list = Sapdb.find_by_sql [READ_ZROH_STK_SQL, werks, year, month, year]
  #   YgtSapErpImgStock.transaction do
  #     list.each do |row|
  #       YgtSapErpImgStock.create(
  #           {
  #             :kucun_date => kucun_date,
  #             :wh_no => werks,
  #             :wh_loc => row.lgort,
  #             :item_no => row.matnr,
  #             :item_depict => row.maktx,
  #             :qty => row.pqty,
  #             :unit => row.meins
  #           }
  #       )
  #     end
  #   end
  # end


end