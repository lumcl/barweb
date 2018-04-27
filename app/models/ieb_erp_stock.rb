class IebErpStock < ActiveRecord::Base

  def self.insert_record
    sql = "
      with
        tmchb as
          (select a.mandt,a.lgort,a.matnr,a.charg,sum(a.clabs+a.cumlm+a.cinsm+a.ceinm+a.cspem+a.cretm) balqty
             from sapsr3.mchb a
           where a.mandt='168' and a.werks='381A' and (a.clabs+a.cumlm+a.cinsm+a.ceinm+a.cspem+a.cretm) > 0
           group by a.mandt,a.lgort,a.matnr,a.charg),
        tmseg as
          (select a.mandt,a.matnr,a.charg,a.ebeln,a.ebelp,a.aufnr,
                  rank () over (partition by a.matnr,a.charg order by b.budat,b.cpudt,b.cputm,a.mjahr,a.mblnr,a.zeile) rank
             from sapsr3.mseg a
               join sapsr3.mkpf b on b.mandt=a.mandt and b.mjahr=a.mjahr and b.mblnr=a.mblnr
             where a.mandt='168' and a.bwart='101' and a.werks='381A' and (a.matnr,a.charg) in (select distinct matnr,charg from tmchb)
          )
      select sysdate stkdate,a.matnr,a.lgort,a.charg,a.balqty,c.meins,b.ebeln,b.ebelp,b.aufnr,
             c.matkl,c.mtart,d.maktx,e.dlrat,f.deuom,f.hstxt,f.cbtyp
        from tmchb a
          join sapsr3.mara c on c.mandt=a.mandt and c.matnr=a.matnr
          join sapsr3.makt d on d.mandt=c.mandt and d.matnr=c.matnr and d.spras='M'
          left join tmseg b on b.mandt=a.mandt and b.matnr=a.matnr and b.charg=a.charg and b.rank = 1
          left join sapsr3.zieba003 e on e.mandt=a.mandt and e.bnarea='5207' and e.bukrs='L300' and e.connr=? and e.matnr=a.matnr
          left join sapsr3.ziebc001 f on f.mandt=e.mandt and f.bnarea=e.bnarea and f.bukrs=e.bukrs and f.connr=e.connr and f.cbtyp=e.cbtyp and f.cbseq=e.cbseq
    "
    list = Sapdb.find_by_sql [sql, Figaro.env.connr]
    list.each do |row|
      IebErpStock.transaction do
        IebErpStock.create(
            {
                stkdate: row.stkdate,
                matnr: row.matnr,
                lgort: row.lgort,
                charg: row.charg,
                balqty: row.balqty,
                meins: row.meins,
                ebeln: row.ebeln,
                ebelp: row.ebelp,
                aufnr: row.aufnr,
                matkl: row.matkl,
                mtart: row.mtart,
                maktx: row.maktx,
                dlrat: row.dlrat,
                deuom: row.deuom,
                hstxt: row.hstxt,
                cbtyp: row.cbtyp,
                status: '10'
            }
        )
      end
    end
    sql = "
      update ieb_erp_stocks a
        set a.aufnr = (select b.aufnr from ieb_erp_stocks b where b.matnr=a.matnr and b.charg=a.charg and nvl(b.aufnr,' ') <> ' ' and rownum = 1)
      where a.mtart <> 'ZROH' and nvl(a.aufnr,' ') = ' ' and nvl(a.ebeln,' ') = ' '
    "
    IebErpStock.connection.execute sql
    create_aufnr_version
  end

  def self.create_aufnr_version
    sql = "
      select distinct a.aufnr from ieb_erp_stocks a
        left join ieb_afpos b on b.aufnr=a.aufnr
      where nvl(a.aufnr,' ') <> ' ' and b.ieb_bom_id is null
    "
    list = IebErpStock.find_by_sql sql
    list.each do |row|
      ieb_afpo = IebAfpo.new
      ieb_afpo.create_ieb_afpo row.aufnr
    end
  end

  def self.insert_to_ygt
    sql = "
      select a.id,a.stkdate,a.lgort,a.matnr,a.maktx,a.balqty,a.meins,
             nvl(a.ebeln,' ') ebeln,a.ebelp,nvl(c.vernr,' ')vernr,a.aufnr,a.charg,a.mtart
        from ieb_erp_stocks a
          left join ieb_afpos b on b.aufnr=a.aufnr
          left join ieb_boms c on c.id = b.ieb_bom_id
      where a.status = '10'
    "
    list = IebErpStock.find_by_sql sql
    list.each do |row|
      IebErpStock.transaction do
        YgtSapErpImgStock.transaction do
          YgtSapErpHalfExgStock.transaction do
            if row.mtart == 'ZFRT' and row.vernr != ' '
              YgtSapErpHalfExgStock.create(
                  {
                      kucun_date: row.stkdate,
                      wh_no: '381A',
                      wh_loc: row.lgort,
                      item_no: row.matnr,
                      pici_no: row.charg,
                      exg_version: row.vernr,
                      item_depict: row.maktx,
                      qty: row.balqty,
                      unit: row.meins,
                      note: "MO:#{row.aufnr}"

                  }
              )
              IebErpStock.update(row.id, status: '20')

            elsif row.mtart == 'ZROH' or row.ebeln != ' '
              YgtSapErpImgStock.create(
                  {
                      kucun_date: row.stkdate,
                      wh_no: '381A',
                      wh_loc: row.lgort,
                      item_no: row.matnr,
                      item_depict: row.maktx,
                      qty: row.balqty,
                      unit: row.meins,
                      note: "PO:#{row.ebeln}.#{row.ebelp}",
                      pici_no: row.charg

                  }
              )
              IebErpStock.update(row.id, status: '20')
            elsif row.mtart == 'ZHLB' and row.vernr != ' '
              YgtSapErpImgStock.create(
                  {
                      kucun_date: row.stkdate,
                      wh_no: '381A',
                      wh_loc: row.lgort,
                      item_no: row.matnr,
                      item_depict: row.maktx,
                      qty: row.balqty,
                      unit: row.meins,
                      note: "MO:#{row.aufnr}",
                      pici_no: row.charg,
                      exg_version: row.vernr,
                      wo_no: row.aufnr
                  }
              )
              IebErpStock.update(row.id, status: '20')
            end
          end
        end
      end
    end
  end

end
