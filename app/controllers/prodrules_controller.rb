class ProdrulesController < ApplicationController
  before_action :set_prodrule, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @page = (params[:page] || 1).to_i
    unless params[:@prodrule].blank? and params[:aufnr].blank? and params[:matnr].blank?
      @prodrule = Prodrule
                       .where("qrcode like '%#{params[:qrcode]}%'")
                       .where("rule like '%#{params[:rule]}%'")
                       .where("matnr like '%#{params[:matnr]}%'")
                       .order(qrcode: :asc)
                       .page(@page)
      @total_count = @prodrule.total_count
    else
      @prodrule = Array.new
    end

    respond_with(@prodrule)

    #@prodrule = Prodrule.all
    #respond_with(@prodrule)
  end

  def show
    respond_with(@prodrule)
  end

  def new
    @prodrule = Prodrule.new
    respond_with(@prodrule)
  end

  def edit
  end

  def create
    @prodrule = Prodrule.new(prodrule_params)
    @prodrule.save
    respond_with(@prodrule)
  end

  def update
    @prodrule.update(prodrule_params)
    respond_with(@prodrule)
  end

  def destroy
    @prodrule.destroy
    respond_with(@prodrule)
  end

  private
    def set_prodrule
      @prodrule = Prodrule.find(params[:id])
    end

    def prodrule_params
      params.require(:prodrule).permit(:qrcode, :rule, :matnr, :muser)
    end
end
