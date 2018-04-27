class IebBomLinesController < ApplicationController
  before_action :set_ieb_bom_line, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @ieb_bom_lines = IebBomLine.all
    respond_with(@ieb_bom_lines)
  end

  def show
    respond_with(@ieb_bom_line)
  end

  def new
    @ieb_bom_line = IebBomLine.new
    respond_with(@ieb_bom_line)
  end

  def edit
  end

  def create
    @ieb_bom_line = IebBomLine.new(ieb_bom_line_params)
    @ieb_bom_line.save
    respond_with(@ieb_bom_line)
  end

  def update
    @ieb_bom_line.update(ieb_bom_line_params)
    respond_with(@ieb_bom_line)
  end

  def destroy
    @ieb_bom_line.destroy
    respond_with(@ieb_bom_line)
  end

  private
    def set_ieb_bom_line
      @ieb_bom_line = IebBomLine.find(params[:id])
    end

    def ieb_bom_line_params
      params.require(:ieb_bom_line).permit(:bom_id, :idnrk, :werks, :menge, :ausch, :apmng, :bond, :dpmatnr)
    end
end
