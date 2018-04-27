class SapSbomtb < ActiveRecord::Base
  self.table_name = 'sap_sbomtb'

  belongs_to :pmatnr_obj, class_name: 'SapMara', foreign_key: 'pmatnr'
  belongs_to :cmatnr_obj, class_name: 'SapMara', foreign_key: 'cmatnr'


  def bom_explosion(werks, pmatnr, qty, boms, parts, partsx, procurement_parts)
    #puts "werks:#{werks} pmatnr:#{pmatnr} qty:#{qty}"
    keys = Array.new
    rows = SapSbomtb.where(werks: werks).where(pmatnr: pmatnr).order(:posnr, :alpos, :alpgr, ewahr: :desc)
    #loop 1 find matched with parts
    #puts rows
    rows.each { |row|
      #set unique key to prevent alternate item double counted
      key = "#{row.werks}@#{row.pmatnr}@#{row.posnr}@#{row.alpos}@#{row.alpgr}"
      unless keys.include?(key)
        if parts.include?(row.cmatnr)
          bom_explosion(row.cwerks, row.cmatnr, row.dusage * qty, boms, parts, partsx, procurement_parts)
          keys.append key
        end
      end
    }

    #loop 2 find matched with partsx
    rows.each { |row|
      #set unique key to prevent alternate item double counted
      key = "#{row.werks}@#{row.pmatnr}@#{row.posnr}@#{row.alpos}@#{row.alpgr}"
      unless keys.include?(key)
        if partsx.include?(row.cmatnr)
          bom_explosion(row.cwerks, row.cmatnr, row.dusage * qty, boms, parts, partsx, procurement_parts)
          keys.append key
        end
      end
    }

    #loop 3 insert procurement_parts
    rows.each { |row|
      #set unique key to prevent alternate item double counted
      key = "#{row.werks}@#{row.pmatnr}@#{row.posnr}@#{row.alpos}@#{row.alpgr}"
      unless keys.include?(key)
        if procurement_parts.include?(row.cmatnr)
          boms.append bom_component row, qty
          keys.append key
        end
      end
    }

    #loop 4 remaining st position
    st_matkl = %w[STH 29-01 29-02]
    st_start = %w[LS 29]
    st_wip = %w[-1 -2 -3 -4 -5 -6 -7 -8 -9]
    rows.each { |row|
      #set unique key to prevent alternate item double counted
      key = "#{row.werks}@#{row.pmatnr}@#{row.posnr}@#{row.alpos}@#{row.alpgr}"
      unless keys.include?(key)
        #exclude all the manufactured ST & DC Cored
        if not row.cmatnr[row.cmatnr.size-3..row.cmatnr.size] == 'LEI' and
            not row.cmatnr[row.cmatnr.size-5..row.cmatnr.size] == 'SUB00'

          #remaining real ST not ST wip
          if st_matkl.include?(row.cmatkl) and st_start.include?(row.cmatnr[0..1]) and
              not st_wip.include?(row.cmatnr[row.cmatnr.size-4..row.cmatnr.size-3])
              boms.append bom_component row, qty
          elsif row.csobsl == '50'
            bom_explosion(row.cwerks, row.cmatnr, row.dusage * qty, boms, parts, partsx, procurement_parts)
          else
            boms.append bom_component row, qty
          end
          keys.append key

        end
      end
    }
  end

  def bom_component(row, qty)
    bom = IebBomLine.new
    bom.connr = Figaro.env.connr
    bom.idnrk = row.cmatnr
    bom.werks = row.cwerks
    bom.menge = row.dusage * qty
    #bom.ausch = row.ckausf
    bom.dpmatnr = row.pmatnr
    bom.bond = row.cwerks == '381A'
    bom
  end

  def purchase_part (matnr)
    return matnr.split('LEI').first if matnr[matnr.size-3..matnr.size] == 'LEI'
    return matnr.split('SUB').first if matnr[matnr.size-5..matnr.size] == 'SUB00'
    matnr
  end

end
