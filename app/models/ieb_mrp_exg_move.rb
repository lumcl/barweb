class IebMrpExgMove < ActiveRecord::Base
  belongs_to :ieb_afpo, class_name: 'IebAfpo', foreign_key: 'aufnr'

  def self.insert_record
    str_date = Date.parse(IebMrpExgMove.maximum(:budat)||'20141231') + 1
    end_date = Time.now.to_date - 1

    sql = "
      select a.budat,b.mjahr,b.mblnr,b.zeile,b.matnr,i.maktx,b.menge,b.meins,b.charg,
         c.vbelv,c.posnv,d.vgbel,d.vgpos,e.bednr,f.auart,f.kunnr bill,g.kunnr,h.name1,
         j.aufnr,d.ntgew,d.brgew,d.gewei,(e.netpr/e.peinh) netpr, k.waers,l.cucur,m.kdmat,lpad(e.afnam,6,'0') afnam
      from sapsr3.mkpf a
        join sapsr3.mseg b on b.mandt=a.mandt and b.mjahr=a.mjahr and b.mblnr=a.mblnr and b.bwart='982' and b.werks='381A'
        left join sapsr3.mseg j on j.mandt=b.mandt and j.matnr=b.matnr and j.charg=b.charg and j.bwart='101' and j.werks=b.werks and j.aufnr <> ' '
        join sapsr3.makt i on i.mandt=b.mandt and i.matnr=b.matnr and i.spras='M'
        left join sapsr3.vbfa c on c.mandt=b.mandt and c.vbeln=b.mblnr and c.posnn=b.line_id and c.mjahr=b.mjahr and c.vbtyp_n='R' and c.vbtyp_v='J'
        left join sapsr3.lips d on d.mandt=c.mandt and d.vbeln=c.vbelv and d.posnr=c.posnv
        left join sapsr3.ekpo e on e.mandt=d.mandt and e.ebeln=d.vgbel and e.ebelp=substr(d.vgpos,2,6)
        left join sapsr3.ekko k on k.mandt=e.mandt and k.ebeln=e.ebeln
        left join sapsr3.ziebb026 l on l.mandt=k.mandt and l.waers=k.waers
        left join sapsr3.vbak f on f.mandt=e.mandt and f.vbeln=e.bednr
        left join sapsr3.vbap m on m.mandt=e.mandt and m.vbeln=e.bednr and m.posnr=lpad(e.afnam,6,'0') and m.matnr=e.matnr
        left join sapsr3.vbpa g on g.mandt=f.mandt and g.vbeln=f.vbeln and g.posnr='000000' and g.parvw='WE'
        left join sapsr3.kna1 h on h.mandt=g.mandt and h.kunnr=g.kunnr
      where a.mandt='168' and a.mjahr='2015' and a.budat between ? and ?
    "
    list = Sapdb.find_by_sql [sql, str_date.strftime('%Y%m%d'), end_date.strftime('%Y%m%d')]
    list.each do |row|
      IebMrpExgMove.transaction do
        IebMrpExgMove.create(
            {
                budat: row.budat,
                mjahr: row.mjahr,
                mblnr: row.mblnr,
                zeile: row.zeile,
                matnr: row.matnr,
                maktx: row.maktx,
                menge: row.menge,
                meins: row.meins,
                charg: row.charg,
                vbeln: row.vbelv,
                posnr: row.posnv,
                vgbel: row.vgbel,
                vgpos: row.vgpos,
                bednr: row.bednr,
                auart: row.auart,
                bill_to: row.bill,
                ship_to: row.kunnr,
                name1: row.name1,
                aufnr: row.aufnr,
                ntgew: row.gewei == 'G' ? row.ntgew * 0.001 : row.ntgew,
                brgew: row.gewei == 'G' ? row.brgew * 0.001 : row.brgew,
                gewei: 'KG',
                status: '10',
                netpr: row.netpr,
                waers: row.cucur,
                kdmat: row.kdmat,
                afnam: row.afnam
            }
        )
      end
    end
  end

end
