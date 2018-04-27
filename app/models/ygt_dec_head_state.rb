class YgtDecHeadState < ActiveRecord::Base
  establish_connection :ygtdb
  self.primary_key = :seq_no
  self.table_name = 'sap.dec_head_state'

  def self.update_sap
    rows = YgtDecHeadState.where(rstat: '1')
    SapSe16n.transaction do
      YgtDecHeadState.transaction do
        IebZiebi001.transaction do
          IebZiebe001.transaction do

            rows.each do |row|
              if row.i_e_flag == 'I'

                IebZiebi001.where(impnr: row.op_no)
                    .update_all(
                        dlfnr: row.entry_id,
                        decdt: row.d_date.strftime('%Y%m%d'),
                        imstu: '3'
                    )

                selections = {
                    IMPNR: row.op_no
                }
                attributes = {
                    IMSTU: '3',
                    DLFNR: row.entry_id,
                    DECDT: row.d_date.strftime('%Y%m%d')
                }
                SapSe16n.create_job('ZIEBI001', 'UPDATE', selections, attributes, '1')

                row.rstat = '3'
                row.save

              else

                IebZiebe001.where(expnr: row.op_no)
                    .update_all(
                        dlfnr: row.entry_id,
                        decdt: row.d_date.strftime('%Y%m%d'),
                        exstu: '3'
                    )

                selections = {
                    EXPNR: row.op_no
                }
                attributes = {
                    EXSTU: '3',
                    DLFNR: row.entry_id,
                    DECDT: row.d_date.strftime('%Y%m%d')
                }
                SapSe16n.create_job('ZIEBE001', 'UPDATE', selections, attributes, '1')

                row.rstat = '3'
                row.save

              end
            end
          end
        end
      end
    end
  end

  def self.daily_update_sap
    sql = "
      SELECT expnr
        FROM sapsr3.ziebe001 a
       WHERE     a.mandt = '168'
             AND a.bnarea = '5207'
             AND a.loekz = ' '
             AND a.crdat >= '20150201'
             AND a.dlfnr = ' '
     "
    rows = Sapdb.find_by_sql sql
    list = Array.new
    rows.each do |r|
      list.append r.expnr
    end

    sql = "
          SELECT distinct op_no, entry_id dlfnr, TO_CHAR (list_declare_date, 'YYYYMMDD') decdt
      FROM v_sap_to_ep
     WHERE entry_id is not null and op_no IN (?)
    "
    records = YgtDecHeadState.find_by_sql [sql, list]

    SapSe16n.transaction do
      records.each do |row|
        selections = {
            EXPNR: row.op_no
        }
        attributes = {
            EXSTU: '3',
            DLFNR: row.dlfnr,
            DECDT: row.decdt
        }
        SapSe16n.create_job('ZIEBE001', 'UPDATE', selections, attributes, '2')
      end
    end

    sql = "
      SELECT impnr
        FROM sapsr3.ziebi001 a
       WHERE     a.mandt = '168'
             AND a.bnarea = '5207'
             AND a.loekz = ' '
             AND a.crdat >= '20150201'
             AND a.dlfnr = ' '
     "
    rows = Sapdb.find_by_sql sql
    list = Array.new
    rows.each do |r|
      list.append r.impnr
    end

    sql = "
          SELECT distinct op_no, entry_id dlfnr, TO_CHAR (list_declare_date, 'YYYYMMDD') decdt
      FROM v_sap_to_ep
     WHERE entry_id is not null and op_no IN (?)
    "
    records = YgtDecHeadState.find_by_sql [sql, list]

    SapSe16n.transaction do
      records.each do |row|
        selections = {
            IMPNR: row.op_no
        }
        attributes = {
            IMSTU: '3',
            DLFNR: row.dlfnr,
            DECDT: row.decdt
        }
        SapSe16n.create_job('ZIEBI001', 'UPDATE', selections, attributes, '2')
      end
    end
  end

  def self.update_trade_date
    connection = YgtDecHeadState.connection

    sql = "
            UPDATE sic.ep_dec_bill_list a
               SET a.trade_date =
                      (SELECT b.budat
                         FROM sapsr3.mkpf@txdb b
                        WHERE     b.mjahr = SUBSTR (a.file_no, 4, 4)
                              AND b.mblnr = SUBSTR (file_no, 9, 10))
             WHERE trade_date IS NULL AND SUBSTR (file_no, 1, 2) = 'MB'
          "
    connection.execute sql

    sql = "
            UPDATE sic.ep_dec_bill_list a
               SET a.trade_date =
                      (SELECT y.budat
                         FROM sapsr3.mseg@txdb x, sapsr3.mkpf@txdb y
                        WHERE     x.ebeln = SUBSTR (a.file_no, 4, 10)
                              AND x.ebelp = SUBSTR (a.file_no, 15, 5)
                              AND y.mjahr = x.mjahr
                              AND y.mblnr = x.mblnr
                              AND y.frbnr = substr(a.order_no,1,15)
                              AND ROWNUM = 1)
             WHERE trade_date IS NULL AND SUBSTR (file_no, 1, 2) = 'PO'
          "
    connection.execute sql


    sql = "
            UPDATE sic.ep_dec_bill_list a
               SET a.trade_date =
                      (SELECT y.budat
                         FROM sapsr3.mkpf@txdb y
                        WHERE  y.frbnr = substr(a.order_no,1,15) AND ROWNUM = 1)
             WHERE     a.trade_date IS NULL
                   AND SUBSTR (a.file_no, 1, 2) = 'PO'
                   AND SUBSTR (inv_no, 1, 3) = 'ITX'
          "
    connection.execute sql
  end

end