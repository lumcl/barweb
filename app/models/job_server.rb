class JobServer < Object

  def self.midnight
    Sql.insert_sapsr3

    connection = YgtErpBillHead.connection
    connection.execute(
    "
      UPDATE sic.ep_dec_bill_list a
         SET a.trade_date =
                (SELECT b.budat
                   FROM sapsr3.mkpf@txdb b
                  WHERE     b.mjahr = SUBSTR (a.file_no, 4, 4)
                        AND b.mblnr = SUBSTR (file_no, 9, 10))
       WHERE trade_date IS NULL AND SUBSTR (file_no, 1, 2) = 'MB'
    ")

    connection.execute(
    "
      UPDATE sic.ep_dec_bill_list a
         SET a.trade_date =
                (SELECT y.budat
                   FROM sapsr3.mseg@txdb x, sapsr3.mkpf@txdb y
                  WHERE     x.ebeln = SUBSTR (a.file_no, 4, 10)
                        AND x.ebelp = SUBSTR (a.file_no, 15, 5)
                        AND y.mjahr = x.mjahr
                        AND y.mblnr = x.mblnr
                        AND y.frbnr = SUBSTR (a.order_no, 1, 15)
                        AND ROWNUM = 1)
       WHERE trade_date IS NULL AND SUBSTR (file_no, 1, 2) = 'PO'
    ")

    connection.execute(
    "
      UPDATE sic.ep_dec_bill_list a
         SET a.trade_date =
                (SELECT y.budat
                   FROM sapsr3.mkpf@txdb y
                  WHERE y.frbnr = SUBSTR (a.order_no, 1, 15) AND ROWNUM = 1)
       WHERE     a.trade_date IS NULL
             AND SUBSTR (a.file_no, 1, 2) = 'PO'
             AND SUBSTR (inv_no, 1, 3) = 'ITX'
    ")

    IebMseg.update_cbseq

    YgtDecHeadState.daily_update_sap
    YgtDecHeadState.update_trade_date

    RptExportGuanFengCheck.run
    RptNewBomMaterial.run
    RptNewBomMaterialDt.run
  end

  def self.download_bom
    begin
      connection = Sql.connection
      connection.begin_db_transaction
      connection.execute('SELECT RID FROM IT.TLOG@ORACLETW WHERE ROWNUM = 1')

      connection.execute('TRUNCATE TABLE SAP_SBOMXTB')
      connection.execute("INSERT INTO SAP_SBOMXTB SELECT ROWNUM ID, WERKS,PMATNR,CMATNR,CMATKL,CWERKS,DUSAGE,DUOM,CKAUSF,CSOBSL,ALPOS,ALPGR,EWAHR,DPMATNR,SYSDATE CRDAT FROM IT.SBOMXTB@ORACLETW WHERE WERKS = '381A'")

      connection.execute('TRUNCATE TABLE SAP_SBOMTB')
      connection.execute("INSERT INTO SAP_SBOMTB SELECT ROWNUM ID, WERKS,PMATNR,POSNR,CMATNR,CMTART,CMATKL,CBESKZ,CSOBSL,CWERKS,ALPOS,ALPGR,EWAHR,DUSAGE,DUOM,SYSDATE CRDAT FROM IT.SBOMTB@ORACLETW WHERE WERKS='381A'")

      connection.commit_db_transaction
      afpo = IebAfpo.new
      afpo.product_order_stocks

      sql = "
            SELECT /*+ DRIVING_SITE(B) */
                  a.aufnr, c.vernr, a.created_at
              FROM ieb_afpos a
                   LEFT JOIN sapsr3.zieba011@sapp b
                      ON a.aufnr = b.aufnr AND b.mandt = '168'
                   JOIN ieb_boms c ON c.id = a.ieb_bom_id
             WHERE (b.aufnr IS NULL OR b.vernr2 = ' ')
            "

    rescue Exception => msg
      connection.rollback_db_transaction
    end
  end

  def self.update_zieb
    YgtPreEms3OrgBomState.update_sap
    YgtPreEms3OrgExgState.upload_sap
    YgtPreEms3OrgImgState.upload_sap
    YgtDecHeadState.update_sap
  end

end