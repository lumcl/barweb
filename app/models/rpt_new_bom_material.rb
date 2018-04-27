class RptNewBomMaterial
  def self.run
    report = RptNewBomMaterial.new
    report.process
  end

  def process
    rows = Sapco.find_by_sql sql

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => '備案料號建議') do |sheet|
        sheet.add_row ['類別', '料號', '規格', '料類', '狀態', '單位', '重量(KG)', '供應商', '名稱']
        rows.each do |row|
          sheet.add_row [row.mtart, row.cmatnr, row.cmaktx, row.cmatkl, row.cmstae, row.meins, row.kg, row.lifnr, row.name1],
                        types: [:string, :string, :string, :string, :string, :string, :float, :string, :string]
        end
      end
      p.serialize('report.xlsx')
    end

    Mail.defaults do
      delivery_method :smtp, address: '172.91.1.253', port: 25
    end

    Mail.deliver do
      from 'lum.cl@l-e-i.com'
      to 'lum.cl@l-e-i.com,jackie.liao@l-e-i.com,davy.zhou@l-e-i.com,splendor.long@l-e-i.com'
      subject '備案料號建議報表 - TX'
      body 'iebweb::app::models::RptNewBomMaterial'
      add_file filename: 'report.xlsx'
    end

  end


  def sql
    "
        SELECT DISTINCT y.mtart,
                        y.cmatnr,
                        y.cmaktx,
                        y.cmatkl,
                        y.cmstae,
                        y.meins,
                        y.kg,
                        z.lifnr,
                        x.name1
          FROM (SELECT /*+ DRIVING_SITE(A) */
                       DISTINCT b.mtart,
                                a.cmatnr,
                                a.cmaktx,
                                a.cmatkl,
                                a.cmstae,
                                b.meins,
                                DECODE (b.gewei, 'G', b.ntgew * 0.001, b.ntgew) kg
                  FROM it.sbomxtb a
                       LEFT JOIN sapsr3.zieba003@sapp i
                          ON     i.mandt = '168'
                             AND i.bnarea = '5207'
                             AND i.bukrs = 'L300'
                             AND i.connr = 'E52070000001'
                             AND i.matnr = a.cmatnr
                       JOIN sapsr3.mara@sapp b
                          ON b.mandt = '168' AND b.matnr = a.cmatnr
                 WHERE     a.werks = '381A'
                       AND a.cwerks = '381A'
                       AND (a.alpos = ' ' OR (a.alpos = 'X' AND a.ewahr = 100))
                       AND a.csobsl <> '50'
                       AND a.pmatnr IN (SELECT DISTINCT matnr
                                          FROM sapsr3.zsd0012@sapp
                                         WHERE werks = '381A' AND delkz = 'FE')
                       AND NOT (   SUBSTR (a.cmatnr, LENGTH (a.cmatnr) - 4, 3) =
                                      'SUB'
                                OR SUBSTR (a.cmatnr, LENGTH (a.cmatnr) - 2, 3) =
                                      'LEI')
                       AND (i.cbseq IS NULL OR i.cbseq = '0000')
                UNION
                SELECT DISTINCT b.mtart,
                                a.matnr,
                                c.maktx,
                                b.matkl,
                                b.mstae,
                                b.meins,
                                DECODE (b.gewei, 'G', b.ntgew * 0.001, b.ntgew) kg
                  FROM sapsr3.zsd0012@sapp a
                       JOIN sapsr3.mara@sapp b
                          ON b.mandt = '168' AND b.matnr = a.matnr
                       JOIN sapsr3.makt@sapp c
                          ON c.mandt = '168' AND c.matnr = a.matnr AND c.spras = 'M'
                       LEFT JOIN sapsr3.zieba003@sapp i
                          ON     i.mandt = '168'
                             AND i.bnarea = '5207'
                             AND i.bukrs = 'L300'
                             AND i.connr = 'E52070000001'
                             AND i.matnr = a.matnr
                 WHERE     a.werks = '381A'
                       AND a.delkz IN ('FE', 'BE')
                       AND NOT (   SUBSTR (a.matnr, LENGTH (a.matnr) - 4, 3) = 'SUB'
                                OR SUBSTR (a.matnr, LENGTH (a.matnr) - 2, 3) = 'LEI')
                       AND (i.cbseq IS NULL OR i.cbseq = '0000')) y
               LEFT JOIN sapsr3.eina@sapp z
                  ON     z.mandt = '168'
                     AND z.matnr = y.cmatnr
                     AND SUBSTR (lifnr, 1, 2) NOT IN ('L1',
                                                      'L2',
                                                      'L3',
                                                      'L4',
                                                      'L7',
                                                      'L9')
               LEFT JOIN sapsr3.lfa1@sapp x
                  ON x.mandt = z.mandt AND x.lifnr = z.lifnr
         WHERE cmstae IN ('AP',
                          'CA',
                          'MV',
                          'MP')
      ORDER BY y.mtart, y.cmatnr
    "
  end
end