class IebZiebi001 < ActiveRecord::Base

  def self.check_booking(impnr)
    message = Array.new
    return message unless impnr[0..2] == 'ITX'
    sql = "
      select b.ebeln,b.ebelp,b.matnr,b.menge,b.meins,c.hstxt,d.lifnr,e.sortl,
      (select sum(c.menge - c.dabmg) from sapsr3.ekes c where c.mandt='168' and c.ebeln=b.ebeln and c.ebelp=b.ebelp) bookqty,
      (select sum(d.menge - d.wemng) from sapsr3.eket d where d.mandt='168' and d.ebeln=b.ebeln and d.ebelp=b.ebelp and d.menge <> 0) balqty
      from sapsr3.ziebi002 b
      join sapsr3.ziebi001 a on a.mandt=b.mandt and a.impnr=b.impnr
      join sapsr3.ekko d on d.mandt=b.mandt and d.ebeln=b.ebeln
      join sapsr3.lfa1 e on e.mandt=d.mandt and e.lifnr=d.lifnr
      left join sapsr3.ziebc001 c on c.mandt=b.mandt and c.bnarea=a.bnarea and c.bukrs=a.bukrs and c.cbtyp=b.cbtyp and c.cbseq=b.cbseq
      where b.mandt='168' and b.impnr=?
      order by b.ebeln,b.ebelp
    "
    list = Sapdb.find_by_sql [sql, impnr]
    list.each do |row|
      if row.menge > (row.bookqty || 0) or row.menge > row.balqty
        message.append "#{impnr}|#{row.ebeln}-#{row.ebelp}|#{row.matnr}|#{row.hstxt}|#{row.menge}|#{row.meins}|#{row.lifnr}|#{row.sortl}"
      end
    end
    message
  end

  def self.get_imstu_eq_1(connr, impnr, crnam)
    sql = "  SELECT A.IMPNR, A.IMDAT, A.IMTYP, A.IMSTU, B.PRTXT IMPORT, C.PRTXT OEPORT,
             A.ITAMT, A.DPSEQ, A.CRNAM, A.LIFNR
        FROM SAPSR3.ZIEBI001 A, SAPSR3.ZIEBB004 B, SAPSR3.ZIEBB004 C
       WHERE     A.MANDT = '168'
             AND A.IMSTU = '1'
             AND A.LOEKZ = ' '
             AND A.BNAREA = ?
             AND A.BUKRS = ?
             AND A.CONNR = ?
             AND B.MANDT = A.MANDT
             AND B.BNAREA = A.BNAREA
             AND B.BUKRS = A.BUKRS
             AND B.PORT = A.IMPORT
             AND C.MANDT = A.MANDT
             AND C.BNAREA = A.BNAREA
             AND C.BUKRS = A.BUKRS
             AND C.PORT = A.OEPORT
             AND A.IMPNR LIKE '%#{impnr}%'
             AND A.CRNAM LIKE '%#{crnam}%'
    ORDER BY A.IMPNR"
    list = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr]
    impnrs = Array.new
    list.each do |row|
      impnrs.append row.impnr
    end

    ieb_impnrs = Array.new
    ziebi001s = IebZiebi001.select(:impnr).where(impnr: impnrs)
    ziebi001s.each do |row|
      ieb_impnrs.append row.impnr
    end

    rows = Array.new
    list.each do |row|
      rows.append row unless ieb_impnrs.include?(row.impnr)
    end

    return rows

  end

end
