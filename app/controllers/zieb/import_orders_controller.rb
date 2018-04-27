class Zieb::ImportOrdersController < ApplicationController
  before_action :set_zieb_import_order, only: [:show, :edit, :update, :destroy,
                                               :create_zieb_import_order_lines,
                                               :display_add_detail_selection_form,
                                               :paste_purchase_order_line,
                                               :create_zieb_import_order_lines_by_po_lines,
                                               :packing_list,
                                               :invoice]

  # GET /zieb/import_orders
  # GET /zieb/import_orders.json

  ZH_FONTS = "#{Rails.root}/app/fonts/kaiu.ttf"

  def index
    @wp_order_no = (params[:wp_order_no]||'').strip.upcase
    if (@wp_order_no == '')
      condition = "elikz <> 'X' or elikz is null"
    else
      condition = "order_no like '%#{@wp_order_no}%'"
    end
    @zieb_import_orders = Zieb::ImportOrder.where(condition).order(:order_no)
  end

  # GET /zieb/import_orders/1
  # GET /zieb/import_orders/1.json
  def show

  end

  # GET /zieb/import_orders/new
  def new
    @zieb_import_order = Zieb::ImportOrder.new
    @zieb_import_order.connr = Figaro.env.connr
    @zieb_import_order.order_date = Time.now.to_date.strftime('%Y%m%d')
    @zieb_import_order.zterm = 'CIF SHENZHEN'
    @zieb_import_order.payment_terms = 'T/T 90DAYS'
    @zieb_import_order.delivery_method = 'TRK'
  end

  # GET /zieb/import_orders/1/edit
  def edit
  end

  # POST /zieb/import_orders
  # POST /zieb/import_orders.json
  def create
    @zieb_import_order = Zieb::ImportOrder.new(zieb_import_order_params)

    respond_to do |format|
      if @zieb_import_order.save
        format.html { redirect_to @zieb_import_order, notice: 'Import order was successfully created.' }
        format.json { render action: 'show', status: :created, location: @zieb_import_order }
      else
        format.html { render action: 'new' }
        format.json { render json: @zieb_import_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /zieb/import_orders/1
  # PATCH/PUT /zieb/import_orders/1.json
  def update
    respond_to do |format|
      if @zieb_import_order.update(zieb_import_order_params)
        format.html { redirect_to @zieb_import_order, notice: 'Import order was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @zieb_import_order }
      else
        format.html { render action: 'edit' }
        format.json { render json: @zieb_import_order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zieb/import_orders/1
  # DELETE /zieb/import_orders/1.json
  def destroy
    @zieb_import_order.destroy
    respond_to do |format|
      format.html { redirect_to zieb_import_orders_url }
      format.json { head :no_content }
    end
  end

  def to_excel
    @zieb_import_orders = Array.new
    @wp_text = params[:wp_text] || ""
    unless @wp_text == ""
      array = text_area_to_array @wp_text
      @zieb_import_orders = Zieb::ImportOrder.where(order_no: array)
    end
    respond_to do |format|
      format.xlsx
    end
  end


  def display_add_detail_selection_form
    #@wp_lifnr = (params[:wp_lifnr]||'').strip.upcase
    @wp_lifnr = @zieb_import_order.lifnr
    @wp_ebeln = (params[:wp_ebeln]||'').strip.upcase
    @wp_matnr = (params[:wp_matnr]||'').strip.upcase
    @wp_lifdn = (params[:wp_lifdn]||'').strip.upcase
    wp_submit = (params[:wp_submit]||'')
    @id = (params[:id]||'').strip.upcase

    if wp_submit == 'X'
      sql = sql_for_po_confirmation
      sql = sql + " AND A.LIFNR = '#{@wp_lifnr}'" if @wp_lifnr != ''
      sql = sql + " AND A.EBELN = '#{@wp_ebeln}'" if @wp_ebeln != ''
      sql = sql + " AND B.MATNR = '#{@wp_matnr}'" if @wp_matnr != ''
      sql = sql + " AND D.LIFDN = '#{@wp_lifdn}'" if @wp_lifdn != ''
      sql = sql + " ORDER BY D.LIFDN, B.MATNR, B.EBELN, B.EBELP, C.ETENS"
      @list = Sql.find_by_sql sql
    end
    render partial: 'display_add_detail_selection_form'
  end

  def paste_purchase_order_line
    @allow_save = true
    @wp_text = params[:wp_text] || ""
    unless @wp_text == ''
      @records = Array.new
      ebeln_ebelp_list = ""
      i = 0
      array = text_area_to_array @wp_text
      array.each do |line|
        if line.include?("\t")
          record = Hash.new
          buf = line.split("\t")
          i = i + 1
          record[:rowid] = i
          record[:ebeln] = buf[0] || ""
          record[:ebelp] = (buf[1] || "").rjust(5, '0')
          record[:menge] = buf[2] || "0"
          record[:netpr] = buf[3] || "0"
          record[:ntgew] = buf[4] || "0"
          record[:brgew] = buf[5] || "0"
          record[:pkqty] = buf[6] || "0"
          record[:corig] = buf[7] || ""
          record[:brand] = buf[8] || ""
          record[:matnr] = ""
          record[:txz01] = ""
          record[:werks] = ""
          record[:waers] = ""
          record[:meins] = ""
          record[:sap_menge] = ""
          record[:sap_netpr] = ""
          record[:class] = "warning"
          record[:menge_class] = "danger text-right"
          record[:netpr_class] = "danger text-right"
          @records << record
          ebeln_ebelp_list = ebeln_ebelp_list + "," if ebeln_ebelp_list.empty? == false
          ebeln_ebelp_list = ebeln_ebelp_list + "('#{record[:ebeln]}','#{record[:ebelp]}')"
        end
      end
      po_confirmations = Sql.find_by_sql sql_for_po_confirmation_by_purchase_order_lines ebeln_ebelp_list
      po_confirmations.each do |p|
        @records.each do |r|
          if r[:ebeln] == p.ebeln and r[:ebelp] == p.ebelp
            r[:matnr] = p.matnr
            r[:txz01] = p.txz01
            r[:werks] = p.werks
            r[:waers] = p.waers
            r[:meins] = p.meins
            r[:sap_menge] = p.menge
            r[:sap_netpr] = p.netpr
            if (r[:menge].to_f == p.menge.to_f) and (r[:netpr].to_f == p.netpr.to_f)
              r[:class] = ""
            end
            r[:menge_class] = "text-right" if (r[:menge].to_f == p.menge.to_f)
            r[:netpr_class] = "text-right" if (r[:netpr].to_f == p.netpr.to_f)
            @allow_save = false if r[:sap_menge].to_f < r[:menge].to_f
            break
          end
        end
      end
    end
  end

  def create_zieb_import_order_lines_by_po_lines
    @wp_text = params[:wp_text] || ""
    unless @wp_text == ''
      @records = Array.new
      ebeln_ebelp_list = ""
      array = text_area_to_array @wp_text
      array.each do |line|
        if line.include?("\t")
          record = Hash.new
          buf = line.split("\t")
          record[:ebeln] = buf[0] || ""
          record[:ebelp] = (buf[1] || "").rjust(5, '0')
          record[:menge] = buf[2] || "0"
          record[:netpr] = buf[3] || "0"
          record[:ntgew] = buf[4] || "0"
          record[:brgew] = buf[5] || "0"
          record[:pkqty] = buf[6] || "0"
          record[:corig] = buf[7] || ""
          record[:brand] = buf[8] || ""
          @records << record
          ebeln_ebelp_list = ebeln_ebelp_list + "," if ebeln_ebelp_list.empty? == false
          ebeln_ebelp_list = ebeln_ebelp_list + "('#{record[:ebeln]}','#{record[:ebelp]}')"
        end
      end
      sql = "SELECT LIFNR,EBELN,EBELP,MATNR,TXZ01,WERKS,WAERS,NETPR,MEINS,SUM(MENGE)MENGE,MIN(LIFDN)LIFDN,MIN(DELDT)DELDT,CBTYP,CBSEQ,DLRAT,HSTXT,HSCODE,DEUOM,NAME1,CUTXT FROM ( "
      sql = sql + sql_for_po_confirmation + "AND (B.EBELN, B.EBELP) IN (#{ebeln_ebelp_list}) "
      sql = sql + " ) GROUP BY LIFNR,EBELN,EBELP,MATNR,TXZ01,WERKS,WAERS,NETPR,MEINS,CBTYP,CBSEQ,DLRAT,HSTXT,HSCODE,DEUOM,NAME1,CUTXT ORDER BY LIFDN,MATNR,EBELN,EBELP"
      po_confirmations = Sql.find_by_sql sql
      Zieb::ImportOrderLine.create_from_po_confirmation_by_po_lines(po_confirmations, @zieb_import_order, @records)
      redirect_to @zieb_import_order
    end
  end

  def create_zieb_import_order_lines
    sql = "SELECT LIFNR,EBELN,EBELP,MATNR,TXZ01,WERKS,WAERS,NETPR,MEINS,SUM(MENGE)MENGE,MIN(LIFDN)LIFDN,MIN(DELDT)DELDT,CBTYP,CBSEQ,DLRAT,HSTXT,HSCODE,DEUOM,NAME1,CUTXT FROM ( "
    sql = sql + sql_for_po_confirmation + " AND C.ROWID IN (?)"
    sql = sql + " ) GROUP BY LIFNR,EBELN,EBELP,MATNR,TXZ01,WERKS,WAERS,NETPR,MEINS,CBTYP,CBSEQ,DLRAT,HSTXT,HSCODE,DEUOM,NAME1,CUTXT ORDER BY LIFDN,MATNR,EBELN,EBELP"
    po_confirmations = Sql.find_by_sql [sql, params[:wp_chkbox]]
    Zieb::ImportOrderLine.create_from_po_confirmation(po_confirmations, @zieb_import_order)
    redirect_to @zieb_import_order
  end

  def doc_header_400(pdf, title)
    top_left_position = pdf.bounds.top
    pdf.bounding_box([0, top_left_position], :width => 260) do
      pdf.font(ZH_FONTS, style: :normal) do
        pdf.text "立德電子股份有限公司", size: 18
      end
      pdf.font("Helvetica", style: :bold)
      pdf.text "LEADER ELECTRONICS INC.", size: 14
      pdf.font(ZH_FONTS, style: :normal) do
        pdf.move_up 2
        pdf.text "新北市新店區寶橋路235巷138號8樓", size: 12
      end
      pdf.font("Helvetica", style: :normal)
      pdf.text "8F., No. 138, Ln. 235, Baoqiao Rd., Xindian Dist., New Taipei City", size: 9
      pdf.text "23145, Taiwan R.O.C.", size: 9
    end
    pdf.bounding_box([380, top_left_position], :width => 155) do
      pdf.font("Helvetica", style: :bold)
      pdf.text "#{title}", size: 20
    end
    pdf.bounding_box([380, top_left_position - 25], :width => 52) do
      pdf.font("Helvetica", style: :bold)
      pdf.text "Doc No.", align: :right, leading: 6
      pdf.text "Date", align: :right, leading: 6
    end
    pdf.bounding_box([440, top_left_position - 25], :width => 100) do
      pdf.font("Helvetica", style: :normal)
      pdf.text @zieb_import_order.order_no, leading: 6
      pdf.text @zieb_import_order.order_date, leading: 6
      pdf.text @zieb_import_order.zieb_import_order_lines.first.werks || '', leading: 6
    end
    pdf.font("Helvetica", style: :normal, size: 10)
    pdf.bounding_box([0, top_left_position - 80], :width => 240) do
      pdf.text "Bill To:", size: 11, style: :bold
      pdf.text "Jiangsu Leader Electronics Inc."
      pdf.text "No. 99, Weijia Lane, Dantu New City, Dantu District,"
      pdf.text "Zhenjiang City, Jiangsu Province, China"
    end
    pdf.bounding_box([282, top_left_position - 80], :width => 240) do
      pdf.text "Ship To:", size: 11, style: :bold
      pdf.text "Jiangsu Leader Electronics Inc."
      pdf.text "No. 99, Weijia Lane, Dantu New City, Dantu District,"
      pdf.text "Zhenjiang City, Jiangsu Province, China"
    end
    pdf.move_down(10)
    data = [
        ["Seller ID", "Reference No", "Paymemt Terms", "Delivery Method", "Delivery Terms"],
        [@zieb_import_order.lifnr, @zieb_import_order.ref_no, @zieb_import_order.payment_terms, @zieb_import_order.delivery_method, @zieb_import_order.zterm]
    ]
    pdf.table(data, cell_style: {width: 102}) do
      row(0).style background_color: 'f0f0f0', font_style: :bold
    end
  end

  def invoice
    pdf = Prawn::Document.new(page_size: 'A4', page_layout: :portrait)
    pdf.repeat(:all) do
      #pdf.stroke_axis
      doc_header_400(pdf, "INVOICE")
    end
    currency = @zieb_import_order.zieb_import_order_lines.first.waers
    data = [["PO No.", "Line", "Group", "Part No.\nDescription", "Quantity", "Unit", "Price\n#{currency}", "Amount\n#{currency}"]]
    meins = %w[EA PC]
    wt_menge = 0
    wt_amount = 0
    qty_decimal = false
    @zieb_import_order.zieb_import_order_lines.each do |line|
      qty_decimal = true if meins.include?(line.meins) == false
      ws_menge = meins.include?(line.meins) ? fmt(line.menge, "%d") : fmt(line.menge, "%.3f")
      ws_netpr = fmt(line.netpr, "%.4f")
      ws_amount = fmt(line.amount, "%.2f")
      wt_amount +=  (line.amount || 0)
      wt_menge += (line.menge  || 0)
      data += [["#{line.ebeln}", "#{line.ebelp}", "#{line.hstxt}", "#{line.matnr}\n#{line.part_no}", "#{ws_menge}", "#{line.meins}", "#{ws_netpr}", "#{ws_amount}"]]
    end
    menge = qty_decimal ? fmt(wt_menge, "%.3f") : fmt(wt_menge, "%d")
    data += [["Total", "", "", "", menge, "", "", fmt(wt_amount, "%.2f")]]

    words = ActionController::Base.helpers.number_to_currency_in_words(wt_amount, connector: ' and ')
    pdf.move_down(10)
    data += [[{content: "(#{currency}) #{words.upcase}", colspan: 8, font_style: :bold}]]

    pdf.bounding_box([0, 580], :width => 520, :height => 570) do
      pdf.table(data, header: true, width: 510, cell_style: {size: 9}) do
        column(2).style font: ZH_FONTS, size: 10
        column(4).style align: :right
        column(6..7).style align: :right
        row(0).style background_color: 'f0f0f0', font: 'Helvetica', font_style: :bold
        row(data.size - 2).style background_color: 'f0f0f0', font: 'Helvetica', font_style: :bold
        column(0).width = 60
        column(1).width = 35
        column(2).width = 70
        column(3).width = 120
      end
    end

    options = {:at => [pdf.bounds.right - 150, 0],
               :width => 150,
               :align => :right,
               :start_count_at => 1
    }
    pdf.number_pages "<page> of <total>", options
    send_data pdf.render, :filename => "I#{@zieb_import_order.order_no}_#{@zieb_import_order.lifnr}.pdf", :type => "application/pdf"
  end

  def packing_list
    pdf = Prawn::Document.new(page_size: 'A4', page_layout: :portrait)
    pdf.repeat(:all) do
      #pdf.stroke_axis
      doc_header_400(pdf, "PACKING LIST")
    end
    data = [["PO No.", "Line", "Group", "Part No.\nDescription", "Quantity", "N.W", "G.W", "Ctns", "C/O", "Brand"]]
    meins = %w[EA PC]
    wt_menge = 0
    wt_ntgew = 0
    wt_brgew = 0
    wt_pkqty = 0
    qty_decimal = false
    @zieb_import_order.zieb_import_order_lines.each do |line|
      qty_decimal = true if meins.include?(line.meins) == false
      ws_menge = meins.include?(line.meins) ? fmt(line.menge, "%d") : fmt(line.menge, "%.3f")
      ws_ntgew = fmt(line.ntgew, "%.2f")
      ws_brgew = fmt(line.brgew, "%.2f")
      ws_pkqty = fmt(line.pkqty, "%d")
      wt_menge += (line.menge || 0)
      wt_ntgew += (line.ntgew || 0)
      wt_brgew += (line.brgew || 0)
      wt_pkqty += (line.pkqty || 0)
      data += [["#{line.ebeln}", "#{line.ebelp}", "#{line.hstxt}", "#{line.matnr}\n#{line.part_no}", "#{ws_menge}", "#{ws_ntgew}", "#{ws_brgew}", "#{ws_pkqty}", "#{line.cktxt}", "#{line.brand}"]]
    end
    menge = qty_decimal ? fmt(wt_menge, "%.3f") : fmt(wt_menge, "%d")
    data += [["Total", "", "", "", menge, fmt(wt_ntgew, "%.2f"), fmt(wt_brgew, "%.2f"), fmt(wt_pkqty, "%d"), "", ""]]

    pdf.bounding_box([0, 580], :width => 520, :height => 570) do
      pdf.table(data, header: true, width: 510, cell_style: {size: 9}) do
        column(2).style font: ZH_FONTS, size: 10
        column(8).style font: ZH_FONTS, size: 10
        column(9).style font: ZH_FONTS, size: 10
        column(4..7).style align: :right
        row(0).style background_color: 'f0f0f0', font: 'Helvetica', font_style: :bold
        row(data.size - 1).style background_color: 'f0f0f0', font: 'Helvetica', font_style: :bold
        column(0).width = 60
        column(1).width = 35
        column(2).width = 70
        column(3).width = 110
        column(4).width = 50
        column(8).width = 35
      end
    end
    options = {:at => [pdf.bounds.right - 150, 0],
               :width => 150,
               :align => :right,
               :start_count_at => 1
    }
    pdf.number_pages "<page> of <total>", options
    send_data pdf.render, :filename => "P#{@zieb_import_order.order_no}_#{@zieb_import_order.lifnr}.pdf", :type => "application/pdf"
  end


  private
  # Use callbacks to share common setup or constraints between actions.
  def set_zieb_import_order
    @zieb_import_order = Zieb::ImportOrder.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def zieb_import_order_params
    params.require(:zieb_import_order).permit(:lifnr, :order_no, :order_date, :order_type, :import_date, :bnarea, :bukrs, :connr, :parvw, :dlfnr, :zterm, :elikz, :ref_no, :delivery_method, :payment_terms)
  end

  def sql_for_po_confirmation_by_purchase_order_lines(ebeln_ebelp_list)
    "
      SELECT /*+ DRIVING_SITE(A) */
            A.LIFNR, B.EBELN, B.EBELP, B.MATNR, B.TXZ01, B.WERKS, A.WAERS,
             (B.NETPR / B.PEINH) NETPR, B.MEINS, SUM ( (C.MENGE - C.DABMG)) MENGE
        FROM SAPSR3.EKKO@SAPP A, SAPSR3.EKPO@SAPP B, SAPSR3.EKES@SAPP C
       WHERE     A.MANDT = '#{Figaro.env.mandt}'
             AND A.LIFNR = '#{@zieb_import_order.lifnr}'
             AND A.LOEKZ = ' '
             AND A.RESWK = ' '
             AND B.MANDT = A.MANDT
             AND B.EBELN = A.EBELN
             AND B.LOEKZ = ' '
             AND B.ELIKZ = ' '
             AND C.MANDT = A.MANDT
             AND C.EBELN = B.EBELN
             AND C.EBELP = B.EBELP
             AND C.EBTYP = 'LA'
             AND C.MENGE > C.DABMG
             AND (B.EBELN, B.EBELP) IN (#{ebeln_ebelp_list})
    GROUP BY A.LIFNR, B.EBELN, B.EBELP, B.MATNR, B.TXZ01,
             B.WERKS, A.WAERS, (B.NETPR / B.PEINH), B.MEINS
    "
  end

  def sql_for_po_confirmation
    "
      SELECT /*+ DRIVING_SITE(A) */
            A.LIFNR, B.EBELN, B.EBELP, C.ETENS, B.MATNR,
             B.TXZ01, B.WERKS, A.WAERS, (B.NETPR / B.PEINH) NETPR, B.MEINS,
             C.EINDT, C.XBLNR, C.ERDAT, C.EZEIT, (C.MENGE - C.DABMG) MENGE,
             C.DABMG, D.LIFDN, D.STATUS, D.DELDT, D.ID,
             D.PARVW, E.CBTYP, E.CBSEQ, E.DLRAT, F.HSTXT,
             F.HSCODE, F.DEUOM, A.MANDT, E.BNAREA, E.CONNR,
             E.BUKRS, C.ROWID EKES_RID, G.NAME1, H.CUTXT
        FROM SAPSR3.EKKO@SAPP A, SAPSR3.EKPO@SAPP B, SAPSR3.EKES@SAPP C, IPS.PO_CONFIRMATIONS D, SAPSR3.ZIEBA003@SAPP E
             , SAPSR3.ZIEBC001@SAPP F, SAPSR3.LFA1@SAPP G, SAPSR3.ZIEBB002@SAPP H
       WHERE     A.MANDT = '#{Figaro.env.mandt}'
             AND A.LOEKZ = ' '
             AND A.RESWK = ' '
             AND B.MANDT = A.MANDT
             AND B.EBELN = A.EBELN
             AND B.LOEKZ = ' '
             AND B.ELIKZ = ' '
             AND C.MANDT = A.MANDT
             AND C.EBELN = B.EBELN
             AND C.EBELP = B.EBELP
             AND C.EBTYP = 'LA'
             AND C.MENGE > C.DABMG
             AND TO_CHAR (D.ID(+)) = C.XBLNR
             AND E.MANDT(+) = B.MANDT
             AND E.BNAREA(+) = '#{@zieb_import_order.bnarea}'
             AND E.BUKRS(+) = '#{@zieb_import_order.bukrs}'
             AND E.CONNR(+) = '#{@zieb_import_order.connr}'
             AND E.MATNR(+) = B.MATNR
             AND F.MANDT(+) = E.MANDT
             AND F.BNAREA(+) = E.BNAREA
             AND F.BUKRS(+) = E.BUKRS
             AND F.CONNR(+) = E.CONNR
             AND F.CBTYP(+) = E.CBTYP
             AND F.CBSEQ(+) = E.CBSEQ
             AND G.LIFNR = A.LIFNR
             AND H.MANDT(+) = F.MANDT
             AND H.CUUOM(+) = F.DEUOM
      "
  end

end
