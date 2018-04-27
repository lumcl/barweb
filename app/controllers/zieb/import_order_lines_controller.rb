class Zieb::ImportOrderLinesController < ApplicationController
  before_action :set_zieb_import_order_line, only: [:show, :edit, :update, :destroy]

  # GET /zieb/import_order_lines
  # GET /zieb/import_order_lines.json
  def index
    @zieb_import_order_lines = Zieb::ImportOrderLine.all
  end

  # GET /zieb/import_order_lines/1
  # GET /zieb/import_order_lines/1.json
  def show
  end

  # GET /zieb/import_order_lines/new
  def new
    @zieb_import_order_line = Zieb::ImportOrderLine.new
  end

  # GET /zieb/import_order_lines/1/edit
  def edit
  end

  # POST /zieb/import_order_lines
  # POST /zieb/import_order_lines.json
  def create
    @zieb_import_order_line = Zieb::ImportOrderLine.new(zieb_import_order_line_params)

    respond_to do |format|
      if @zieb_import_order_line.save
        format.html { redirect_to @zieb_import_order_line, notice: 'Import order line was successfully created.' }
        format.json { render :show, status: :created, location: @zieb_import_order_line }
      else
        format.html { render :new }
        format.json { render json: @zieb_import_order_line.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /zieb/import_order_lines/1
  # PATCH/PUT /zieb/import_order_lines/1.json
  def update
    respond_to do |format|
      if @zieb_import_order_line.update(zieb_import_order_line_params)
        format.html { redirect_to @zieb_import_order_line.zieb_import_order, notice: 'Import order line was successfully updated.' }
        format.json { render :show, status: :ok, location: @zieb_import_order_line.zieb_import_order }
      else
        format.html { render :edit }
        format.json { render json: @zieb_import_order_line.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zieb/import_order_lines/1
  # DELETE /zieb/import_order_lines/1.json
  def destroy
    zieb_import_order = @zieb_import_order_line.zieb_import_order
    @zieb_import_order_line.destroy
    respond_to do |format|
      format.html { redirect_to zieb_import_order}
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zieb_import_order_line
      @zieb_import_order_line = Zieb::ImportOrderLine.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def zieb_import_order_line_params
      params.require(:zieb_import_order_line).permit(:zieb_import_order_id, :update_item_supplier, :order_no, :seq, :lifnr, :name1, :lifdn, :lifdn_date, :ebeln, :ebelp, :etens, :matnr, :txz01, :werks, :waers, :netpr, :meins, :xblnr, :menge, :amount, :cbtyp, :cbseq, :hstxt, :dlrat, :dlqty, :ntgew, :brgew, :corig, :pktyp, :pkqty, :pkuom, :brand, :part_no, :part_desc)
    end
end
