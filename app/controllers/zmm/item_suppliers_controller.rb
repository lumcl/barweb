class Zmm::ItemSuppliersController < ApplicationController
  before_action :set_zmm_item_supplier, only: [:show, :edit, :update, :destroy]

  # GET /zmm/item_suppliers
  # GET /zmm/item_suppliers.json
  def index
    @wp_lifnr = (params[:wp_lifnr]||'').strip.upcase
    @wp_matnr = (params[:wp_matnr]||'').strip.upcase
    if (@wp_lifnr + @wp_matnr == '')
      @zmm_item_suppliers = Zmm::ItemSupplier
      .where("elikz <> 'X' or elikz is null")
      .order(:matnr, :lifnr)
    else
      @zmm_item_suppliers = Zmm::ItemSupplier
      .where("lifnr like '%#{@wp_lifnr}%'")
      .where("matnr like '%#{@wp_matnr}%'")
      .order(:matnr, :lifnr)
    end
  end

  # GET /zmm/item_suppliers/1
  # GET /zmm/item_suppliers/1.json
  def show
  end

  # GET /zmm/item_suppliers/new
  def new
    @zmm_item_supplier = Zmm::ItemSupplier.new
  end

  # GET /zmm/item_suppliers/1/edit
  def edit
  end

  # POST /zmm/item_suppliers
  # POST /zmm/item_suppliers.json
  def create
    @zmm_item_supplier = Zmm::ItemSupplier.new(zmm_item_supplier_params)

    respond_to do |format|
      if @zmm_item_supplier.save
        format.html { redirect_to @zmm_item_supplier, notice: 'Item supplier was successfully created.' }
        format.json { render :show, status: :created, location: @zmm_item_supplier }
      else
        format.html { render :new }
        format.json { render json: @zmm_item_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /zmm/item_suppliers/1
  # PATCH/PUT /zmm/item_suppliers/1.json
  def update
    respond_to do |format|
      if @zmm_item_supplier.update(zmm_item_supplier_params)
        format.html { redirect_to @zmm_item_supplier, notice: 'Item supplier was successfully updated.' }
        format.json { render :show, status: :ok, location: @zmm_item_supplier }
      else
        format.html { render :edit }
        format.json { render json: @zmm_item_supplier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zmm/item_suppliers/1
  # DELETE /zmm/item_suppliers/1.json
  def destroy
    @zmm_item_supplier.destroy
    respond_to do |format|
      format.html { redirect_to zmm_item_suppliers_url }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_zmm_item_supplier
    @zmm_item_supplier = Zmm::ItemSupplier.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def zmm_item_supplier_params
    params.require(:zmm_item_supplier).permit(:matnr, :maktx, :lifnr, :sortl, :part_no, :part_desc, :brand, :corig, :cktxt, :pkuom, :ntgew, :brgew, :agent, :maker_name, :elikz)
  end
end
