class IebMrpExgMovesController < ApplicationController
  before_action :set_ieb_mrp_exg_move, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @page = (params[:page] || 1).to_i
    if params[:command] == 'no_bom'
      sql = "
        select a.*
          from ieb_mrp_exg_moves a
            left join ieb_afpos b on b.aufnr=a.aufnr
          where b.ieb_bom_id is null and a.auart='ZC4' and a.status='10'
          order by a.budat desc
      "
      records = IebMrpExgMove.find_by_sql sql
      @ieb_mrp_exg_moves = Kaminari.paginate_array(records).page(@page)
    elsif params[:command] == 'no_mo'
      @ieb_mrp_exg_moves = IebMrpExgMove.where(auart: 'ZC4').where(status: '10').where("nvl(aufnr,' ')=' '").page
    else
      @ieb_mrp_exg_moves = IebMrpExgMove.where(auart: 'ZC4').all.page
    end
    respond_with(@ieb_mrp_exg_moves)
  end

  def show
    respond_with(@ieb_mrp_exg_move)
  end

  def new
    @ieb_mrp_exg_move = IebMrpExgMove.new
    respond_with(@ieb_mrp_exg_move)
  end

  def edit
  end

  def create
    @ieb_mrp_exg_move = IebMrpExgMove.new(ieb_mrp_exg_move_params)
    @ieb_mrp_exg_move.save
    respond_with(@ieb_mrp_exg_move)
  end

  def update
    @ieb_mrp_exg_move.update(ieb_mrp_exg_move_params)
    respond_with(@ieb_mrp_exg_move)
  end

  def destroy
    @ieb_mrp_exg_move.destroy
    respond_with(@ieb_mrp_exg_move)
  end

  private
    def set_ieb_mrp_exg_move
      @ieb_mrp_exg_move = IebMrpExgMove.find(params[:id])
    end

    def ieb_mrp_exg_move_params
      params.require(:ieb_mrp_exg_move).permit(:budat, :mjahr, :mblnr, :zeile, :matnr, :maktx, :menge, :meins, :charg, :vbeln, :posnr, :vgbel, :vgpos, :bednr, :auart, :bill_to, :ship_to, :name1, :aufnr, :ntgew, :brgew, :gewei, :status, :created_by, :updated_by, :created_ip, :updated_ip)
    end
end
