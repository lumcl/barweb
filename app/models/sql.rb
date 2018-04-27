class Sql < ActiveRecord::Base

  def self.ziebr005
    Sql.find_by_sql ['select * from sapsr3.ziebr005@sapp where mandt=?', Figaro.env.mandt]
  end

  def self.ziebb012
    Sql.find_by_sql ["select cland, cktxt, cland||'-'||cktxt ctext from sapsr3.ziebb012@sapp where mandt = ?", Figaro.env.mandt]
  end

  def self.ziebb005
    Sql.find_by_sql ["select pktyp, pktxt, pktyp||'-'||pktxt pktxt from sapsr3.ziebb005@sapp where mandt = ? and bnarea = ? and bukrs =?", Figaro.env.mandt, Figaro.env.bnarea, Figaro.env.bukrs]
  end


  def self.cost_centers
    sql = "
      SELECT A.KOSTL, A.KOSTL||'-'||B.KTEXT CTEXT, B.KTEXT
        FROM SAPSR3.CSKS@SAPP A, SAPSR3.CSKT@SAPP B
       WHERE     A.MANDT = ?
             AND A.KOKRS = '3058'
             AND A.DATBI = '99991231'
             AND B.MANDT = A.MANDT
             AND B.KOKRS = A.KOKRS
             AND B.KOSTL = A.KOSTL
             AND B.SPRAS = 'M'
    "
    Sql.find_by_sql [sql, Figaro.env.mandt]
  end

  def self.execute(sql)
    begin
      puts sql
      ActiveRecord::Base.connection.execute sql
    rescue Exception => msg
      puts msg
    end
  end

  def self.insert_sapsr3
    sql = 'SELECT MAX(CPUDT) CPUDT FROM SAPSR3.MKPF'
    rows = Sql.find_by_sql sql
    cpudt = rows.first.cpudt
    connection = ActiveRecord::Base.connection
    begin
      connection.begin_db_transaction
      sql = "INSERT INTO SAPSR3.MSEG
         SELECT B.*
           FROM SAPSR3.MKPF@SAPP A, SAPSR3.MSEG@SAPP B
          WHERE     A.MANDT = '168'
                AND B.MANDT = '168'
                AND B.MBLNR = A.MBLNR
                AND B.MJAHR = A.MJAHR
                AND A.CPUDT > '#{cpudt}'
                AND A.CPUDT < TO_CHAR(SYSDATE,'YYYYMMDD')
                AND B.BWART NOT LIKE ('3%')"
      connection.execute sql

      sql = "INSERT INTO SAPSR3.MKPF
         SELECT A.*
           FROM SAPSR3.MKPF@SAPP A
          WHERE     A.MANDT = '168'
                AND A.CPUDT > '#{cpudt}'
                AND A.CPUDT < TO_CHAR(SYSDATE,'YYYYMMDD')"
      connection.execute sql

      sql = "INSERT INTO SAPSR3.EKPA
         SELECT *
           FROM SAPSR3.EKPA@SAPP
          WHERE     MANDT = '168'
                AND PARZA = '001'
                AND ERDAT > '#{cpudt}'
                AND ERDAT < TO_CHAR (SYSDATE, 'YYYYMMDD')"
      connection.execute sql

      sql = "INSERT INTO SAPSR3.EKBE
         SELECT *
           FROM SAPSR3.EKBE@SAPP
          WHERE     MANDT = '168'
                AND VGABE IN ('1', '2')
                AND CPUDT > '#{cpudt}'
                AND CPUDT < TO_CHAR (SYSDATE, 'YYYYMMDD')"
      connection.execute sql

      sql = "INSERT INTO SAP_MSEG
         SELECT A.MBLNR, A.MJAHR, B.ZEILE, A.VGART, A.BLART, BUDAT, A.CPUDT,
                A.CPUTM, A.XBLNR, A.FRBNR,B.LINE_ID, A.LE_VBELN, B.BWART, B.MATNR, B.WERKS,
                B.LGORT, B.CHARG, B.LIFNR, B.KUNNR, B.SHKZG, B.WAERS, B.DMBTR,
                B.MENGE, B.MEINS, B.AUFNR, B.RSNUM, B.RSPOS, B.EBELN, B.EBELP,
                B.LFBNR, B.LFPOS, B.AKTNR, B.VFDAT,B.SJAHR,B.SMBLN,B.SMBLP,
                '1' RSTAT, SYSDATE UPTIM
           FROM SAPSR3.MKPF A, SAPSR3.MSEG B
          WHERE     A.MANDT = '168'
                AND B.MANDT = '168'
                AND B.MBLNR = A.MBLNR
                AND B.MJAHR = A.MJAHR
                AND A.CPUDT > '#{cpudt}'
                AND A.CPUDT < TO_CHAR(SYSDATE, 'YYYYMMDD')
                AND B.WERKS = '381A'
                AND B.BWART NOT LIKE ('3%')"
      connection.execute sql
      connection.commit_db_transaction
    rescue
      connection.rollback_db_transaction
    end
  end

  def z_update_ygt
    connection = YgtErpBillHead.connection
    begin
      connection.begin_db_transaction
      z_update_ygt_sql_scripts.split(';').each do |sql|
        connection.execute sql
      end
      connection.commit_db_transaction
    rescue Exception => msg
      connection.rollback_db_transaction
    end
  end

  def z_update_ygt_sql_scripts
    "
    UPDATE sic.ep_dec_bill_list a
       SET a.trade_date =
              (SELECT b.budat
                 FROM sapsr3.mkpf@txdb b
                WHERE     b.mjahr = SUBSTR (a.file_no, 4, 4)
                      AND b.mblnr = SUBSTR (file_no, 9, 10))
     WHERE remark2 IS NULL AND SUBSTR (file_no, 1, 2) = 'MB';

    UPDATE sic.ep_dec_bill_list a
       SET a.trade_date =
              (SELECT y.budat
                 FROM sapsr3.mseg@txdb x, sapsr3.mkpf@txdb y
                WHERE     x.ebeln = SUBSTR (a.file_no, 4, 10)
                      AND x.ebelp = SUBSTR (a.file_no, 15, 5)
                      AND y.mjahr = x.mjahr
                      AND y.mblnr = x.mblnr
                      AND y.frbnr = a.order_no
                      AND ROWNUM = 1)
     WHERE trade_date IS NULL AND SUBSTR (file_no, 1, 2) = 'PO';

    UPDATE sic.ep_dec_bill_list a
       SET a.trade_date =
              (SELECT y.budat
                 FROM sapsr3.mkpf@txdb y
                WHERE y.frbnr = a.order_no AND ROWNUM = 1)
     WHERE     a.trade_date IS NULL
           AND SUBSTR (a.file_no, 1, 2) = 'PO'
           AND SUBSTR (inv_no, 1, 3) = 'ITX'
  "
  end

  def z_execute
    connection = ActiveRecord::Base.connection
    begin
      connection.begin_db_transaction
      sql_scripts.split(';').each do |sql|
        connection.execute sql
      end
      connection.commit_db_transaction
      afpo = IebAfpo.new
      afpo.product_order_stocks
    rescue Exception => msg
      connection.rollback_db_transaction
    end
  end

  def sql_scripts
    "
    SELECT RID FROM IT.TLOG@ORACLETW WHERE ROWNUM = 1;

    DROP TABLE SAP_SBOMXTB;
    CREATE TABLE SAP_SBOMXTB AS SELECT ROWNUM ID, WERKS,PMATNR,CMATNR,CMATKL,CWERKS,DUSAGE,DUOM,CKAUSF,CSOBSL,ALPOS,ALPGR,EWAHR,DPMATNR,SYSDATE CRDAT FROM IT.SBOMXTB@ORACLETW WHERE WERKS = '381A';
    CREATE UNIQUE INDEX SAP_SBOMXTB_A ON SAP_SBOMXTB (ID);
    CREATE INDEX SAP_SBOMXTB_B ON SAP_SBOMXTB (WERKS,PMATNR);

    DROP TABLE SAP_SBOMTB;
    CREATE TABLE SAP_SBOMTB AS
    SELECT ROWNUM ID, WERKS,PMATNR,POSNR,CMATNR,CMTART,CMATKL,CBESKZ,CSOBSL,CWERKS,ALPOS,ALPGR,EWAHR,DUSAGE,DUOM,SYSDATE CRDAT FROM IT.SBOMTB@ORACLETW WHERE WERKS='381A';
    CREATE UNIQUE INDEX SAP_SBOMTB_A ON SAP_SBOMTB (ID);
    CREATE INDEX SAP_SBOMTB_B ON SAP_SBOMTB (WERKS,PMATNR)
    "
  end


end
