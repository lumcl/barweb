class IebAfposController < ApplicationController
  before_action :set_ieb_afpo, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    error_status = params[:error_status] || ''
    aufnr = params[:aufnr] || ''
    aufnrs = params[:aufnrs] || Array.new
    matnr = params[:matnr] || ''
    @page = (params[:page] || 1).to_i

    criteria = error_status + aufnr + matnr + aufnrs.join(',')

    if criteria == ''
      records = IebAfpo.where('ieb_bom_id is null').order(aufnr: :asc)
    elsif not aufnrs.empty?
      records = IebAfpo.where(aufnr: aufnrs).order(aufnr: :asc)
    elsif error_status == 'A'
      records = IebAfpo.where('ieb_bom_id is null')
                       .where("aufnr like '%#{aufnr}%'")
                       .where("matnr like '%#{matnr}%'")
                       .order(aufnr: :asc)
    elsif error_status == 'B'
      records = IebAfpo.where('ieb_bom_id is not null')
                       .where("aufnr like '%#{aufnr}%'")
                       .where("matnr like '%#{matnr}%'")
                       .order(aufnr: :asc)
    else
      records = IebAfpo.where("aufnr like '%#{aufnr}%'")
                       .where("matnr like '%#{matnr}%'")
                       .order(aufnr: :asc)
    end
    @ieb_afpos = Kaminari.paginate_array(records).page(@page)

    respond_with(@ieb_afpos)
  end

  def show
    respond_with(@ieb_afpo)
  end

  def new
    @ieb_afpo = IebAfpo.new
    respond_with(@ieb_afpo)
  end

  def edit
  end

  def create
    @ieb_afpo = IebAfpo.new(ieb_afpo_params)
    @ieb_afpo.save
    respond_with(@ieb_afpo)
  end

  def update
    @ieb_afpo.update(ieb_afpo_params)
    respond_with(@ieb_afpo)
  end

  def destroy
    @ieb_afpo.destroy
    respond_with(@ieb_afpo)
  end

  def calculate_bom
    unless params[:ids].nil?
      afpos = IebAfpo.where(aufnr: params[:ids])
      afpo = IebAfpo.new
      afpo.batch_bom_allocations(afpos)
    end
    unless params[:aufnr].nil?
      afpo = IebAfpo.new
      afpo.create_ieb_afpo(params[:aufnr])
    end
    redirect_to ieb_afpos_url({aufnr: params[:aufnr], aufnrs: params[:ids]}), notice: '工單備案BOM計算完畢...'
  end


  private
  def set_ieb_afpo
    @ieb_afpo = IebAfpo.find(params[:id])
  end

  def ieb_afpo_params
    params.require(:ieb_afpo).permit(:aufnr, :matnr, :bom_id, :psmng, :wemng, :apmng, :received, :received_at, :declared, :declared_at, :finished, :finished_at, :analysed, :analysed_at, :sap_updated, :sap_updated_at)
  end
end
