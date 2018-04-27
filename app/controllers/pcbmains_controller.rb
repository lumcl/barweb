class PcbmainsController < ApplicationController
  before_action :set_pcbmain, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @pcbmains = Pcbmain.all
    respond_with(@pcbmains)
  end

  def show
    respond_with(@pcbmain)
  end

  def new
    @pcbmain = Pcbmain.new
    respond_with(@pcbmain)
  end

  def edit
  end

  def create
    @pcbmain = Pcbmain.new(pcbmain_params)
    @pcbmain.save
    respond_with(@pcbmain)
  end

  def update
    @pcbmain.update(pcbmain_params)
    respond_with(@pcbmain)
  end

  def destroy
    @pcbmain.destroy
    respond_with(@pcbmain)
  end

  private
    def set_pcbmain
      @pcbmain = Pcbmain.find(params[:id])
    end

    def pcbmain_params
      params.require(:pcbmain).permit(:id, :pcblabel, :panellabel, :clientip)
    end
end
