class RptExportGuanFengCheck

  def self.run
    report = RptExportGuanFengCheck.new
    report.process
  end

  def process
    valids = Array.new
    invalids = Array.new

    rows = Sql.find_by_sql sql
    rows.each do |row|
      key = "#{row.matnr}.#{row.kunnr}.#{row.cbseq}"
      if row.flag == 'Y'
        valids.push(key) unless valids.include?(key)
      else
        invalids.push(row) unless valids.include?(key)
      end
    end

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => '關封不足') do |sheet|
        sheet.add_row ['機種', '客戶', '名稱', '項號', '關封', '核准日', '有效日', 'HS碼', '品名', '數量', '最早出貨', '最晚出貨', '狀態']
        invalids.each do |row|
          sheet.add_row [row.matnr, row.kunnr, row.name1, row.cbseq, row.closn, row.aprdt, row.valdt, row.hscode, row.hstxt, row.menge, row.dat00, row.dat01, row.flag],
                        types: [:string, :string, :string, :string, :string, :string, :string, :string, :string, :float, :string, :string, :string]
        end
      end
      p.serialize('report.xlsx')
    end

    Mail.defaults do
      delivery_method :smtp, address: '172.31.1.253', port: 25
    end

    Mail.deliver do
      from 'lum.cl@l-e-i.com'
      to 'lum.cl@l-e-i.com,jackie.liao@l-e-i.com,seling.huang@l-e-i.com'
      subject '出口轉廠關封檢查報表'
      body 'iebweb::app::models::RptExportGuanFengCheck'
      add_file filename: 'report.xlsx'
    end


  end

  def sql
    "
      SELECT matnr,
             kunnr,
             name1,
             cbseq,
             closn,
             aprdt,
             valdt,
             hscode,
             hstxt,
             menge,
             dat00,
             dat01,
             case
                when closn is null or hscode is null or valdt < dat01 or aprdt > dat00 then 'N'
                when valdt > dat01 then 'Y'
             end flag
        FROM (  SELECT a.matnr,
                       c.kunnr,
                       d.name1,
                       e.cbseq,
                       f.closn,
                       f.aprdt,
                       f.valdt,
                       g.hscode,
                       g.hstxt,
                       g.menge,
                       MIN (dat00) dat00,
                       MAX (dat00) dat01
                  FROM sapsr3.zsd0012@sapp a
                       JOIN sapsr3.vbak@sapp b
                          ON     b.mandt = a.mandt
                             AND b.vbeln = a.delnr
                             AND b.vtweg = 'TX'
                             AND b.auart = 'ZC4'
                       JOIN sapsr3.vbpa@sapp c
                          ON     c.mandt = a.mandt
                             AND c.vbeln = a.delnr
                             AND c.posnr = '000000'
                             AND c.parvw = 'WE'
                       JOIN sapsr3.kna1@sapp d
                          ON d.mandt = a.mandt AND d.kunnr = c.kunnr
                       LEFT JOIN sapsr3.zieba003@sapp e
                          ON     e.mandt = a.mandt
                             AND e.bnarea = '5207'
                             AND e.bukrs = 'L300'
                             AND e.connr = 'E52070000001'
                             AND e.matnr = a.matnr
                       LEFT JOIN sapsr3.ziebe005@sapp f
                          ON     f.mandt = a.mandt
                             AND f.bnarea = e.bnarea
                             AND f.bukrs = e.bukrs
                             AND f.kunnr = c.kunnr
                             AND f.cancl = ' '
                             AND f.valdt >= TO_CHAR (SYSDATE, 'YYYYMMDD')
                             AND SUBSTR (f.remark, 1, 1) = 'F'
                       LEFT JOIN sapsr3.ziebe006@sapp g
                          ON     g.mandt = f.mandt
                             AND g.bnarea = f.bnarea
                             AND g.bukrs = f.bukrs
                             AND g.closn = f.closn
                             AND g.cbseq = e.cbseq
                             AND g.connr = e.connr
                             AND g.cbtyp = e.cbtyp
                 WHERE     a.delkz = 'VC'
                       AND a.werks NOT IN ('281A')
                       AND a.dat00 < TO_CHAR (SYSDATE + 90, 'YYYYMMDD')
              GROUP BY a.matnr,
                       c.kunnr,
                       d.name1,
                       e.cbseq,
                       f.closn,
                       f.aprdt,
                       f.valdt,
                       g.hscode,
                       g.hstxt,
                       g.menge)
    ORDER BY
             flag desc,
             matnr,
             kunnr,
             cbseq,
             hscode
    "
  end
end