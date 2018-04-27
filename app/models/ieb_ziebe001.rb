class IebZiebe001 < ActiveRecord::Base

  def self.get_exstu_eq_1(connr, expnr, crnam)
    sql = "SELECT A.EXPNR, A.EXPDAT, A.EXTYP, A.EXSTU, B.PRTXT EXPORT, C.PRTXT OEPORT,
             A.ITAMT, A.DPSEQ, A.CRNAM, A.KUNNR
        FROM SAPSR3.ZIEBE001 A, SAPSR3.ZIEBB004 B, SAPSR3.ZIEBB004 C
       WHERE     A.MANDT = '168'
             AND A.EXSTU = '1'
             AND A.LOEKZ = ' '
             AND A.BNAREA = ?
             AND A.BUKRS = ?
             AND A.CONNR = ?
             AND B.MANDT = A.MANDT
             AND B.BNAREA = A.BNAREA
             AND B.BUKRS = A.BUKRS
             AND B.PORT = A.EXPORT
             AND C.MANDT = A.MANDT
             AND C.BNAREA = A.BNAREA
             AND C.BUKRS = A.BUKRS
             AND C.PORT = A.OEPORT
             AND A.EXPNR LIKE '%#{expnr}%'
             AND A.CRNAM LIKE '%#{crnam}%'
    ORDER BY A.EXPNR"
    list = Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, connr]
    expnrs = Array.new
    list.each do |row|
      expnrs.append row.expnr
    end

    ieb_expnrs = Array.new
    ziebe001s = IebZiebe001.select(:expnr).where(expnr: expnrs)
    ziebe001s.each do |row|
      ieb_expnrs.append row.expnr
    end

    rows = Array.new
    list.each do |row|
      rows.append row unless ieb_expnrs.include?(row.expnr)
    end

    return rows
  end
end
