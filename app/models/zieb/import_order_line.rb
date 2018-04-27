class Zieb::ImportOrderLine < ActiveRecord::Base

  attr_accessor :update_item_supplier

  before_create :z_before_create
  before_save :z_before_save

  belongs_to :zieb_import_order, :class_name => 'Zieb::ImportOrder', foreign_key: 'zieb_import_order_id'

  def self.create_from_po_confirmation_by_po_lines (po_confirmations, import_order, records)
    po_confirmations.each do |po_confirmation|
      e = Zieb::ImportOrderLine.new
      e.zieb_import_order_id = import_order.id
      e.mandt = Figaro.env.mandt
      e.order_no = import_order.order_no
      e.lifnr = po_confirmation.lifnr
      e.name1 = po_confirmation.name1
      e.lifdn = po_confirmation.lifdn
      e.lifdn_date = po_confirmation.deldt
      e.ebeln = po_confirmation.ebeln
      e.ebelp = po_confirmation.ebelp
      e.matnr = po_confirmation.matnr
      e.txz01 = po_confirmation.txz01
      e.werks = po_confirmation.werks
      e.waers = po_confirmation.waers
      e.netpr = po_confirmation.netpr
      e.meins = po_confirmation.meins
      e.menge = po_confirmation.menge
      e.cbtyp = po_confirmation.cbtyp
      e.cbseq = po_confirmation.cbseq
      e.hstxt = po_confirmation.hstxt
      e.dlrat = po_confirmation.dlrat
      e.cutxt = po_confirmation.cutxt
      item_supplier = Zmm::ItemSupplier.where(lifnr: e.lifnr).where(matnr: e.matnr).first
      unless item_supplier.nil?
        e.brand = item_supplier.brand
        e.cktxt = item_supplier.cktxt
        e.corig = item_supplier.corig
        e.part_desc = item_supplier.part_desc
        e.part_no = item_supplier.part_no
        e.pkuom = item_supplier.pkuom
      end
      records.each do |hash|
        if (hash[:ebeln] == e.ebeln) and (hash[:ebelp] == e.ebelp)
          e.menge = hash[:menge].to_f if hash[:menge].to_f > 0
          e.ntgew = hash[:ntgew].to_f
          e.brgew = hash[:brgew].to_f
          e.pkqty = hash[:pkqty].to_i
          e.brand = hash[:brand] if hash[:brand] != ''
          e.corig = hash[:corig] if hash[:corig] != ''
          e.cktxt = e.country_name if hash[:corig] != ''
          break
        end
      end
      e.save
    end
  end

  def self.create_from_po_confirmation (po_confirmations, import_order)
    po_confirmations.each do |po_confirmation|
      e = Zieb::ImportOrderLine.new
      e.zieb_import_order_id = import_order.id
      e.mandt = Figaro.env.mandt
      e.order_no = import_order.order_no
      e.lifnr = po_confirmation.lifnr
      e.name1 = po_confirmation.name1
      e.lifdn = po_confirmation.lifdn
      e.lifdn_date = po_confirmation.deldt
      e.ebeln = po_confirmation.ebeln
      e.ebelp = po_confirmation.ebelp
      e.matnr = po_confirmation.matnr
      e.txz01 = po_confirmation.txz01
      e.werks = po_confirmation.werks
      e.waers = po_confirmation.waers
      e.netpr = po_confirmation.netpr
      e.meins = po_confirmation.meins
      e.menge = po_confirmation.menge
      e.cbtyp = po_confirmation.cbtyp
      e.cbseq = po_confirmation.cbseq
      e.hstxt = po_confirmation.hstxt
      e.dlrat = po_confirmation.dlrat
      e.cutxt = po_confirmation.cutxt
      item_supplier = Zmm::ItemSupplier.where(lifnr: e.lifnr).where(matnr: e.matnr).first
      unless item_supplier.nil?
        e.brand = item_supplier.brand
        e.brgew = item_supplier.brgew * e.menge
        e.cktxt = item_supplier.cktxt
        e.corig = item_supplier.corig
        e.ntgew = item_supplier.ntgew * e.menge
        e.part_desc = item_supplier.part_desc
        e.part_no = item_supplier.part_no
        e.pkuom = item_supplier.pkuom
      end
      e.save
    end
  end

  def z_before_create
    self.seq = (Zieb::ImportOrderLine.where(zieb_import_order_id: zieb_import_order_id).maximum("seq") || 0) + 1
    self.mandt = Figaro.env.mandt
  end

  def z_before_save
    self.cktxt = country_name if corig_changed?
    self.amount = menge * netpr
    self.dlqty = menge * (dlrat || 0)
    update_item_supplier_record if update_item_supplier == 'X'
  end

  def country_name
    return '' if corig == ''
    list = Sql.find_by_sql ["select cktxt from sapsr3.ziebb012@sapp where mandt = ? and cland = ?", Figaro.env.mandt, corig]
    return list.first.cktxt
  end

  def update_item_supplier_record
    item_supplier = Zmm::ItemSupplier.where(lifnr: lifnr).where(matnr: matnr).first
    unless item_supplier.nil?
      item_supplier.brand = brand
      item_supplier.cktxt = cktxt
      item_supplier.corig = corig
      item_supplier.part_desc = part_desc
      item_supplier.part_no = part_no
      item_supplier.pkuom = pkuom
      item_supplier.elikz = 'X'
      item_supplier.save
    end
  end


end
