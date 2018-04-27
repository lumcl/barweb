class IebZiebc001sController < ApplicationController
  before_action :set_ieb_ziebc001, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    connr = params[:connr] || Figaro.env.connr
    crdat = params[:crdat] || Time.now.strftime('%Y%m%d')
    @ieb_ziebc001s = IebZiebc001.get_rstat_eq_1(connr,crdat)
    respond_with(@ieb_ziebc001s)
  end

  def upload_ygt
    flash[:notice] = IebZiebc001.upload_ygt(params[:connr], params[:ids]) if params[:ids]
    redirect_to ieb_ziebc001s_url({connr: params[:connr]})
  end

  def show
    respond_with(@ieb_ziebc001)
  end

  def new
    @ieb_ziebc001 = IebZiebc001.new
    respond_with(@ieb_ziebc001)
  end

  def edit
  end

  def create
    @ieb_ziebc001 = IebZiebc001.new(ieb_ziebc001_params)
    @ieb_ziebc001.save
    respond_with(@ieb_ziebc001)
  end

  def update
    @ieb_ziebc001.update(ieb_ziebc001_params)
    respond_with(@ieb_ziebc001)
  end

  def destroy
    @ieb_ziebc001.destroy
    respond_with(@ieb_ziebc001)
  end

  private
    def set_ieb_ziebc001
      @ieb_ziebc001 = IebZiebc001.find(params[:id])
    end

    def ieb_ziebc001_params
      params.require(:ieb_ziebc001).permit(:connr, :cbtyp, :cbseq, :hstxt, :smode, :deuom, :fsuom, :rstat)
    end
end
