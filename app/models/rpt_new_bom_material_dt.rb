class RptNewBomMaterialDt
  def self.run
    report = RptNewBomMaterialDt.new
    report.process
  end

  def process
    rows = Sapco.find_by_sql sql

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => '備案料號建議') do |sheet|
        sheet.add_row ['類別', '料號', '規格', '料類', '狀態', '單位', '重量(KG)', '備案', '協議價', '移動平均', '標準成本', '計劃2']
        rows.each do |row|
          sheet.add_row [row.mtart, row.cmatnr, row.cmaktx, row.cmatkl, row.cmstae, row.meins, row.kg, row.rstat, row.dtfp, row.verpr, row.stprs, row.zplp2],
                        types: [:string, :string, :string, :string, :string, :string, :float, :string, :float, :float, :float, :float]
        end
      end
      p.serialize('report.xlsx')
    end

    Mail.defaults do
      delivery_method :smtp, address: '172.91.1.253', port: 25
    end

    Mail.deliver do
      from 'lum.cl@l-e-i.com'
      to 'lum.cl@l-e-i.com,dennis.sun@l-e-i.com,yoyo.he@l-e-i.com'
      subject '備案料號建議報表 - DT'
      body 'iebweb::app::models::RptNewBomMaterialDt'
      add_file filename: 'report.xlsx'
    end

  end


  def sql
    "
      SELECT DISTINCT z.mtart,
                      z.cmatnr,
                      z.cmaktx,
                      z.cmatkl,
                      z.cmstae,
                      z.meins,
                      z.kg,
                      z.rstat,
                      NVL (p.dtfp, 0) dtfp,
                      m.verpr / m.peinh verpr,
                      m.stprs / m.peinh stprs,
                      m.zplp2 / m.peinh zplp2
        FROM (SELECT /*+ DRIVING_SITE(A) */
                     DISTINCT b.mtart,
                              a.cmatnr,
                              a.cmaktx,
                              a.cmatkl,
                              a.cmstae,
                              b.meins,
                              DECODE (b.gewei, 'G', b.ntgew * 0.001, b.ntgew) kg,
                              i.rstat
                FROM it.sbomxtb a
                     LEFT JOIN sapsr3.zieba003@sapp i
                        ON     i.mandt = '168'
                           AND i.bnarea = '2300'
                           AND i.bukrs = 'L400'
                           AND i.connr = 'E23070000001'
                           AND i.matnr = a.cmatnr
                     JOIN sapsr3.mara@sapp b
                        ON b.mandt = '168' AND b.matnr = a.cmatnr
               WHERE     a.werks = '481A'
                     AND a.cwerks = '481A'
                     AND (a.alpos = ' ' OR (a.alpos = 'X' AND a.ewahr = 100))
                     AND a.csobsl <> '50'
                     AND a.pmatnr IN (SELECT DISTINCT matnr
                                        FROM sapsr3.zsd0012@sapp
                                       WHERE werks = '481A' AND delkz = 'FE')
                     AND NOT (   SUBSTR (a.cmatnr, LENGTH (a.cmatnr) - 4, 3) =
                                    'SUB'
                              OR SUBSTR (a.cmatnr, LENGTH (a.cmatnr) - 2, 3) =
                                    'LEI')
                     AND (i.cbseq IS NULL OR i.cbseq = '0000' OR i.rstat = '1')
              UNION
              SELECT DISTINCT b.mtart,
                              a.matnr,
                              c.maktx,
                              b.matkl,
                              b.mstae,
                              b.meins,
                              DECODE (b.gewei, 'G', b.ntgew * 0.001, b.ntgew) kg,
                              i.rstat
                FROM sapsr3.zsd0012@sapp a
                     JOIN sapsr3.mara@sapp b
                        ON b.mandt = '168' AND b.matnr = a.matnr
                     JOIN sapsr3.makt@sapp c
                        ON c.mandt = '168' AND c.matnr = a.matnr AND c.spras = 'M'
                     LEFT JOIN sapsr3.zieba003@sapp i
                        ON     i.mandt = '168'
                           AND i.bnarea = '2300'
                           AND i.bukrs = 'L400'
                           AND i.connr = 'E23070000001'
                           AND i.matnr = a.matnr
               WHERE     a.werks = '481A'
                     AND a.delkz IN ('FE',
                                     'BE',
                                     'VC',
                                     'VJ')
                     AND NOT (   SUBSTR (a.matnr, LENGTH (a.matnr) - 4, 3) = 'SUB'
                              OR SUBSTR (a.matnr, LENGTH (a.matnr) - 2, 3) = 'LEI')
                     AND (i.cbseq IS NULL OR i.cbseq = '0000' OR i.rstat = '1')) z
             LEFT JOIN it.wpirs p ON p.matnr = z.cmatnr
             LEFT JOIN sapsr3.mbew@sapp m
                ON     m.mandt = '168'
                   AND m.matnr = z.cmatnr
                   AND m.bwkey = '481A'
                   AND m.bwtar = ' '
    "
  end
end