class IebZiebe001sController < ApplicationController
  before_action :set_ieb_ziebe001, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    connr = params[:connr] || Figaro.env.connr
    expnr = params[:expnr] || ''
    crnam = params[:crnam] || ''
    @ieb_ziebe001s = IebZiebe001.get_exstu_eq_1 connr, expnr, crnam
    respond_with(@ieb_ziebe001s)
  end

  def upload_ygt
    if params[:ids]
      messages = Array.new
      params[:ids].each do |expnr|
        messages.append YgtErpBillHead.upload_export_data(expnr)
      end
      flash[:notice] = messages.join("\n")
    end
    redirect_to ieb_ziebe001s_url
  end

  def show
    respond_with(@ieb_ziebe001)
  end

  def new
    @ieb_ziebe001 = IebZiebe001.new
    respond_with(@ieb_ziebe001)
  end

  def edit
  end

  def create
    @ieb_ziebe001 = IebZiebe001.new(ieb_ziebe001_params)
    @ieb_ziebe001.save
    respond_with(@ieb_ziebe001)
  end

  def update
    @ieb_ziebe001.update(ieb_ziebe001_params)
    respond_with(@ieb_ziebe001)
  end

  def destroy
    @ieb_ziebe001.destroy
    respond_with(@ieb_ziebe001)
  end

  private
    def set_ieb_ziebe001
      @ieb_ziebe001 = IebZiebe001.find(params[:id])
    end

    def ieb_ziebe001_params
      params.require(:ieb_ziebe001).permit(:expnr, :extyp, :exstu, :expdat, :dlfnr, :decdt, :created_by, :updated_by)
    end
end
