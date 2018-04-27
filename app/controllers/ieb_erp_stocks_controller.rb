class IebErpStocksController < ApplicationController
  before_action :set_ieb_erp_stock, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @ieb_erp_stocks = IebErpStock.all
    respond_with(@ieb_erp_stocks)
  end

  def show
    respond_with(@ieb_erp_stock)
  end

  def new
    @ieb_erp_stock = IebErpStock.new
    respond_with(@ieb_erp_stock)
  end

  def edit
  end

  def create
    @ieb_erp_stock = IebErpStock.new(ieb_erp_stock_params)
    @ieb_erp_stock.save
    respond_with(@ieb_erp_stock)
  end

  def update
    @ieb_erp_stock.update(ieb_erp_stock_params)
    respond_with(@ieb_erp_stock)
  end

  def destroy
    @ieb_erp_stock.destroy
    respond_with(@ieb_erp_stock)
  end

  private
    def set_ieb_erp_stock
      @ieb_erp_stock = IebErpStock.find(params[:id])
    end

    def ieb_erp_stock_params
      params.require(:ieb_erp_stock).permit(:stkdate, :matnr, :lgort, :charg, :balqty, :meins, :ebeln, :ebelp, :aufnr, :matkl, :mtart, :maktx, :dlrat, :deuom, :hstxt, :cbtyp)
    end
end
