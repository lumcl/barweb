class IebZiebi001sController < ApplicationController
  before_action :set_ieb_ziebi001, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    connr = params[:connr] || Figaro.env.connr
    impnr = params[:impnr] || ''
    crnam = params[:crnam] || ''
    @ieb_ziebi001s = IebZiebi001.get_imstu_eq_1 connr, impnr, crnam
    respond_with(@ieb_ziebi001s)
  end

  def upload_ygt
    if params[:ids]
      messages = Array.new
      @booking_message = Array.new
      params[:ids].each do |impnr|
        check_booking_message = IebZiebi001.check_booking(impnr)
        if check_booking_message.empty?
          messages.append YgtErpBillHead.upload_import_data(impnr)
        else
          @booking_message = @booking_message + check_booking_message
        end
      end
      flash[:notice] = messages.join("\n")
    elsif not params[:impnr].empty?

    end
    if @booking_message.empty?
      redirect_to ieb_ziebi001s_url
    end

  end


  def show
    respond_with(@ieb_ziebi001)
  end

  def new
    @ieb_ziebi001 = IebZiebi001.new
    respond_with(@ieb_ziebi001)
  end

  def edit
  end

  def create
    @ieb_ziebi001 = IebZiebi001.new(ieb_ziebi001_params)
    @ieb_ziebi001.save
    respond_with(@ieb_ziebi001)
  end

  def update
    @ieb_ziebi001.update(ieb_ziebi001_params)
    respond_with(@ieb_ziebi001)
  end

  def destroy
    @ieb_ziebi001.destroy
    respond_with(@ieb_ziebi001)
  end

  private
  def set_ieb_ziebi001
    @ieb_ziebi001 = IebZiebi001.find(params[:id])
  end

  def ieb_ziebi001_params
    params.require(:ieb_ziebi001).permit(:impnr, :imtyp, :imstu, :imdat, :dlfnr, :decdt, :created_by, :updated_by)
  end
end
