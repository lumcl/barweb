class SapSe16nsController < ApplicationController
  before_action :set_sap_se16n, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @sap_se16ns = SapSe16n.all
    respond_with(@sap_se16ns)
  end

  def show
    respond_with(@sap_se16n)
  end

  def new
    @sap_se16n = SapSe16n.new
    respond_with(@sap_se16n)
  end

  def edit
  end

  def create
    @sap_se16n = SapSe16n.new(sap_se16n_params)
    @sap_se16n.save
    respond_with(@sap_se16n)
  end

  def update
    @sap_se16n.update(sap_se16n_params)
    respond_with(@sap_se16n)
  end

  def destroy
    @sap_se16n.destroy
    respond_with(@sap_se16n)
  end

  private
    def set_sap_se16n
      @sap_se16n = SapSe16n.find(params[:id])
    end

    def sap_se16n_params
      params.require(:sap_se16n).permit(:status, :table_name, :action_type, :selection_keys, :selection_values, :attribute_keys, :attribute_values, :error_msg, :updated_ip, :sap_updated_at)
    end
end
