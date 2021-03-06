class YgtErpBillHead < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_key = 'ems_list_no'
  self.table_name = 'sap.erp_bill_head'

  # IMTYP
  #I	直接進口
  #CI	轉廠進口
  #RI	復運進口

  # IMSTU
  #1	建立
  #2	報關中
  #3	報關完成
  #4	核銷

  def selfupload_import_data(impnr)
    message = I18n.t('upload_success')
    begin
      YgtErpBillHead.transaction do
        YgtErpBillList.transaction do
          sql = "SELECT * FROM SAPSR3.ZIEBI001 WHERE MANDT='168' AND IMPNR = ?"
          i001 = (Sapdb.find_by_sql [sql, impnr]).first

          sql = "SELECT A.*, B.CUCUR,
                (SELECT B.LIFNR FROM SAPSR3.EKKO B WHERE B.MANDT='168' AND B.EBELN=A.EBELN) LIFNR
                FROM SAPSR3.ZIEBI002 A, SAPSR3.ZIEBB026 B WHERE A.MANDT = '168' AND A.IMPNR = ?
                AND B.MANDT(+)='168' AND B.WAERS(+) = A.WAERS AND A.APMNG > 0"
          i002 = Sapdb.find_by_sql [sql, impnr]

          YgtErpBillHead.create! ({
                                     ems_no: i001.connr,
                                     ems_list_no: i001.impnr,
                                     agent_code: '4419940946', #find....
                                     i_e_port: i001.import,
                                     master_customs: i001.oeport,
                                     i_e_mark: 'I',
                                     g_mark: i002[0].cbtyp == 'R' ? '3' : '4',
                                     trans_mode: i001.satyp,
                                     trade_mode: i001.dltyp,
                                     input_date: i001.imdat,
                                     note: '',
                                     parking_type: i001.pktyp
                                 })

          i002.each do |row|

            currency_factor = 1.0
            if row.waers == 'JPY' or row.waers == 'TWD'
              currency_factor = 100.0
              SapSe16n.transaction do
                selections = {IMPNR: impnr, IMPIM: row.impim}
                attributes = {WRBTR: (row.wrbtr * 100).to_s}
                SapSe16n.create_job('ZIEBI002', 'UPDATE', selections, attributes, '2')
              end
            end


            if row.mblnr != ' '
              tag = "MB:#{row.mjahr}.#{row.mblnr}.#{row.zeile}"
            elsif row.vbeln_dn != ' '
              tag = "DN:#{row.vbeln_dn}.#{row.posnr_dn}"
            else
              tag = "PO:#{row.ebeln}.#{row.ebelp}"
            end

            YgtErpBillList.create!({
                                       op_no: row.impnr,
                                       list_g_no: row.impim,
                                       cop_g_no: row.matnr,
                                       dec_price: (row.apmng == 0 ? 0 : ((row.wrbtr.to_f * currency_factor) / row.apmng.to_f).round(5)),
                                       qty: row.apmng,
                                       dec_total: (row.wrbtr.to_f * currency_factor),
                                       exg_version: row.vernr,
                                       use_type: '05',
                                       duty_mode: row.duway,
                                       country_code: row.corig,
                                       curr: row.cucur,
                                       tag: tag,
                                       dn: row.vbeln_dn,
                                       dn_line: row.posnr_dn,
                                       ent_qty: row.menge,
                                       inv_no: row.invnr,
                                       supplier_no: row.lifnr,
                                       wet_wt: row.gewei == 'KG' ? row.ntgew : (row.ntgew * 0.001).round(5),
                                       gross_wt: row.gewei == 'KG' ? row.brgew : (row.brgew * 0.001).round(5),
                                       pack_no: row.itamt
                                   })
          end

          SapSe16n.transaction do
            IebZiebi001.transaction do
              selections = {IMPNR: impnr}
              attributes = {
                  IMSTU: '2',
                  DWDAT: Time.now.strftime('%Y%m%d'),
                  DWTIM: Time.now.strftime('%H%M%S')
              }
              SapSe16n.create_transaction('ZIEBI001', 'UPDATE', selections, attributes)

              IebZiebi001.create!({
                                      imdat: i001.imdat,
                                      impnr: impnr,
                                      imstu: '2',
                                      imtyp: i001.imtyp
                                  })
            end
          end
        end
      end
    rescue Exception => ex
      message = ex.message
    end
    return "#{impnr} #{message}"
  end

  def self.upload_export_data(expnr)
    message = I18n.t('upload_success')
    begin
      YgtErpBillHead.transaction do
        YgtErpBillList.transaction do
          sql = "SELECT * FROM SAPSR3.ZIEBE001 WHERE MANDT='168' AND EXPNR = ?"
          e001 = (Sapdb.find_by_sql [sql, expnr]).first
          sql = "SELECT A.*, B.CUCUR
                  FROM SAPSR3.ZIEBE002 A, SAPSR3.ZIEBB026 B
                 WHERE A.MANDT = '168' AND A.EXPNR = ? AND B.MANDT(+) = '168' AND B.WAERS(+) = A.WAERS
                  ORDER BY A.EXPIM
                "
          e002 = Sapdb.find_by_sql [sql, expnr]

          YgtErpBillHead.create! ({
                                     ems_no: e001.connr,
                                     ems_list_no: e001.expnr,
                                     agent_code: '4419940946', #find....
                                     i_e_port: e001.export,
                                     master_customs: e001.oeport,
                                     i_e_mark: 'E',
                                     g_mark: e002[0].cbtyp == 'R' ? '3' : '4',
                                     trans_mode: e001.satyp,
                                     trade_mode: e001.dltyp,
                                     input_date: e001.expdat,
                                     note: '',
                                     parking_type: e001.pktyp
                                 })

          #get default value for packaging type, country code
          ws_pktyp = e001.pktyp
          ws_dest = e002.first.dest

          e002.each do |row|
            if row.mblnr != ' '
              tag = "MB:#{row.mjahr}.#{row.mblnr}.#{row.zeile}"
            elsif row.vbeln_so != ' '
              tag = "SO:#{row.vbeln_so}.#{row.posnr_so}"
            else
              tag = "DN:#{row.vbeln}.#{row.posnr}"
            end

            YgtErpBillList.create!({
                                       op_no: row.expnr,
                                       list_g_no: row.expim,
                                       cop_g_no: row.matnr,
                                       dec_price: (row.netpr.to_f / row.peinh.to_f).round(5),
                                       qty: row.apmng,
                                       dec_total: (row.netpr.to_f * row.menge.to_f / row.peinh.to_f).round(5),
                                       exg_version: row.vernr,
                                       use_type: '05',
                                       duty_mode: row.duway,
                                       #country_code: row.dest, -- change to default as first row
                                       country_code: ws_dest,
                                       curr: row.cucur,
                                       tag: tag,
                                       dn: row.vbeln,
                                       dn_line: row.posnr,
                                       ent_qty: row.menge,
                                       inv_no: row.aufnr,
                                       supplier_no: e001.kunnr == ' ' ? e001.lifnr : e001.kunnr,
                                       wet_wt: row.gewei == 'KG' ? row.ntgew : (row.ntgew * 0.001).round(5),
                                       gross_wt: row.gewei == 'KG' ? row.brgew : (row.brgew * 0.001).round(5),
                                       pack_no: row.itamt
                                   })

            if row.dest != ws_dest or row.pktyp != ws_pktyp
              SapSe16n.transaction do
                selections = {EXPNR: expnr, EXPIM: row.expim}
                attributes = {DEST: ws_dest, PKTYP: ws_pktyp}
                SapSe16n.create_job('ZIEBE002', 'UPDATE', selections, attributes, '2')
              end
            end

          end

          SapSe16n.transaction do
            IebZiebe001.transaction do
              selections = {EXPNR: expnr}
              attributes = {
                  EXSTU: '2',
                  DWDAT: Time.now.strftime('%Y%m%d'),
                  DWTIM: Time.now.strftime('%H%M%S')
              }
              SapSe16n.create_transaction('ZIEBE001', 'UPDATE', selections, attributes)

              IebZiebe001.create!({
                                      expdat: e001.expdat,
                                      expnr: e001.expnr,
                                      exstu: '2',
                                      extyp: e001.extyp
                                  })

            end
          end

        end
      end
    rescue Exception => ex
      message = ex.message
    end
    return "#{expnr} #{message}"
  end

end
