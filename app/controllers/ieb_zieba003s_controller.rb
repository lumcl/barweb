class IebZieba003sController < ApplicationController
  before_action :set_ieb_zieba003, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    connr = params[:connr] || Figaro.env.connr
    @ieb_zieba003s = IebZieba003.not_reported_materials connr
    respond_with(@ieb_zieba003s)
  end

  def upload_ygt
    flash[:notice] = IebZieba003.upload_ygt(params[:connr], params[:ids]) if params[:ids]
    redirect_to ieb_zieba003s_url({connr: params[:connr]})
  end

  def show
    respond_with(@ieb_zieba003)
  end

  def new
    @ieb_zieba003 = IebZieba003.new
    respond_with(@ieb_zieba003)
  end

  def edit
  end

  def create
    @ieb_zieba003 = IebZieba003.new(ieb_zieba003_params)
    @ieb_zieba003.save
    respond_with(@ieb_zieba003)
  end

  def update
    @ieb_zieba003.update(ieb_zieba003_params)
    respond_with(@ieb_zieba003)
  end

  def destroy
    @ieb_zieba003.destroy
    respond_with(@ieb_zieba003)
  end

  private
    def set_ieb_zieba003
      @ieb_zieba003 = IebZieba003.find(params[:id])
    end

    def ieb_zieba003_params
      params.require(:ieb_zieba003).permit(:connr, :matnr, :cbtyp, :cbseq, :dlrat, :fsrat, :rstat)
    end
end
