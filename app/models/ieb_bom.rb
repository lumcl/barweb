class IebBom < ActiveRecord::Base
  has_many :ieb_bom_lines, -> { order('idnrk') },
           class_name: 'IebBomLine', primary_key: 'id', foreign_key: 'ieb_bom_id', dependent: :destroy

  before_create :z_before_create

  RSTAT = {
      '1' => '未備案',
      '2' => '備案中',
      '3' => '完成'
  }

  def z_before_create
    vernr_max = IebBom.where(matnr: matnr).where("vernr between #{Time.now.strftime('%y%m%d')}00 and #{Time.now.strftime('%y%m%d')}99").maximum(:vernr)
    self.vernr = vernr_max.nil? ? "#{Time.now.strftime('%y%m%d')}01" : "#{vernr_max.to_i + 1}"
    self.rstat = '1'
    self.connr = Figaro.env.connr if connr.nil?
    self.menge = 1
  end


  def match_or_create(bom_lines)
    ws_hash = Hash.new
    message = Array.new
    bom_lines.each do |row|
      if row.werks == '381A'
#        zieba003 = SapZieba003.where(connr: row.connr).where(matnr: row.idnrk).first
        sql = "SELECT CONNR, CBTYP, CBSEQ, MATNR, DLRAT, FSRAT, RSTAT FROM SAPSR3.ZIEBA003 WHERE MANDT='168' AND BNAREA=? AND BUKRS=? AND CONNR =? AND MATNR=? AND CBTYP='R'"
        zieba003 = (Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, row.connr, row.idnrk]).first
        unless zieba003.nil?
          if ws_hash.key?(zieba003.cbseq)
            ws_hash[zieba003.cbseq] += row.menge * zieba003.dlrat
          else
            ws_hash[zieba003.cbseq] = row.menge * zieba003.dlrat
          end
        end

        if zieba003.nil? or zieba003.cbseq.nil? or zieba003.cbseq == '0000' or zieba003.cbseq == '9999'
          message.append row.idnrk
        end
      end
    end
    return nil, "#{message.uniq.join(',')} 未歸并" unless message.empty?

    bom_id = nil

    IebBom.where(connr: connr).where(matnr: matnr).where(home_made_parts: home_made_parts == '' ? nil : home_made_parts)
        .order(vernr: :desc).each do |row|
      db_hash = Hash.new
      IebBomLine.where(ieb_bom_id: row.id).where(werks: '381A').select(:connr, :idnrk, :menge).each do |xrow|
#        zieba003 = SapZieba003.where(connr: xrow.connr).where(matnr: xrow.idnrk).first
        sql = "SELECT CONNR, CBTYP, CBSEQ, MATNR, DLRAT, FSRAT, RSTAT FROM SAPSR3.ZIEBA003 WHERE MANDT='168' AND BNAREA=? AND BUKRS=? AND CONNR =? AND MATNR=? AND CBTYP = 'R'"
        zieba003 = (Sapdb.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, xrow.connr, xrow.idnrk]).first
        unless zieba003.nil?
          if db_hash.key?(zieba003.cbseq)
            db_hash[zieba003.cbseq] += xrow.menge * zieba003.dlrat
          else
            db_hash[zieba003.cbseq] = xrow.menge * zieba003.dlrat
          end
        end
      end

      #compare 2 hashtable contents
      if ws_hash == db_hash
        bom_id = row.id
        break
      end
    end

    if bom_id.nil?
      save
      bom_id = id
      bom_lines.each { |row|
        row.ieb_bom_id = id
        row.save
      }
    end

    return bom_id
  end


end
