class QacodesController < ApplicationController
  before_action :set_qacode, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @page = (params[:page] || 1).to_i
    unless params[:qacode].blank? and params[:aufnr].blank? and params[:matnr].blank?
      @qacodes = Qacode
                     .where("qrcode like '%#{params[:qrcode]}%'")
                     .where("aufnr like '%#{params[:aufnr]}%'")
                     .where("matnr like '%#{params[:matnr]}%'")
                     .order(qrcode: :asc)
                     .page(@page)
      @total_count = @qacodes.total_count
    else
      @qacodes = Array.new
    end

    respond_with(@qacodes)
  end

  def show
    respond_with(@qacode)
  end

  def new
    @qacode = Qacode.new
    respond_with(@qacode)
  end

  def process_sony_cycle
    qr = Qacode.where("qrcode=?",params[:qrcode]).where("cycle=?",params[:cycle])
    if params[:cycle].length < 1
      render js: "
        document.getElementById('dacuo').play();
        $('#status').html('<h1 style=color:red> 周期不能为空! <h1/><br/>');
              "
    elsif params[:code_length].to_i > 0 and params[:qrcode].length != params[:code_length].to_i
      render js: "
        document.getElementById('dacuo').play();
        $('#status').html('<h1 style=color:red>#{params[:qrcode]} - 條碼長度不符! <h1/><br/>');
              "
    elsif qr.empty?
      begin
        @qacode = Qacode.create!(
            {
                qrcode: params[:qrcode],
                aufnr: params[:aufnr],
                matnr: params[:matnr],
                cycle: params[:cycle],
                muser: request.ip
            }
        )
        counter = Qacode.where(aufnr: params[:aufnr], cycle: params[:cycle]).count
        code_length_str = ''
        code_length_str = "$('#code_length').val('#{params[:qrcode].length}');" if params[:code_length].to_i == 0
        render js: "
                      $('#status').html('#{params[:qrcode]} - 條碼正確. <br/>');
                      $('#counter').val('#{counter}');
                      #{code_length_str};
                 "
      rescue
        render js: "
                      document.getElementById('dacuo').play();
                      $('#status').html('<h1 style=color:red>#{params[:qrcode]} - 條碼重複! <h1/><br/>');
              "
      end
    else
      render js: "
                      document.getElementById('dacuo').play();
                      $('#status').html('<h1 style=color:red>#{params[:qrcode]} - 條碼存在! <h1/><br/>');
              "
    end
  end

  def read_sony_cycle

  end

  def get_product_order
    sql = "select aufnr,matnr from sapsr3.afpo where mandt='168' and aufnr = ?"
    list = Sapdb.find_by_sql [sql, params[:aufnr].rjust(12, '0')]
    if list.empty?
      render js: "
             $('#matnr').val('');
             $('#aufnr').val('');
             $('#counter').val('');
             $('#code_length').val('');
             $('#aufnr').focus();
             alert('工單號碼輸入錯誤!');
             "
    else
      sql = 'select count(*) counter, nvl(max(length(qrcode)),0) code_length from qrcode.qacodes where aufnr = ?'
      rows = Qacode.find_by_sql [sql, list.first.aufnr]
      render js: "
             $('#matnr').val('#{list.first.matnr}');
             $('#aufnr').val('#{list.first.aufnr}');
             $('#counter').val('#{rows.first.counter}');
             $('#code_length').val('#{rows.first.code_length}');
             "
    end
  end

  def show_material_issue
    sql = "
      with
        taufm as (
          select b.matkl,a.matnr,c.maktx,a.werks,a.charg,decode(a.shkzg,'H',a.menge,a.menge * -1) menge, a.meins,a.budat
            from sapsr3.aufm a
              join sapsr3.mara b on b.mandt=a.mandt and b.matnr=a.matnr
              join sapsr3.makt c on c.mandt=b.mandt and c.matnr=b.matnr and c.spras='M'
            where a.mandt='168' and a.aufnr=? and a.bwart in ('261','262')
        ),
        tmseg as (
          select f.matnr,f.charg,f.ebeln,f.ebelp,f.lifnr,
                 rank() over (partition by f.matnr,f.charg order by f.mjahr, f.mblnr, f.zeile) rank
            from (select d.matnr,d.charg from taufm d group by d.matnr,d.charg) e
              join sapsr3.mseg f on f.mandt='168' and f.matnr=e.matnr and f.charg=e.charg and f.bwart='101' and f.ebeln <> ' '
        )
        select a.matkl,a.matnr,a.maktx,a.werks,a.charg,a.menge,a.meins,a.budat,
               b.ebeln,b.ebelp,b.lifnr,c.sortl,d.licha
          from taufm a
            left join tmseg b on b.matnr=a.matnr and b.charg=a.charg and b.rank = 1
            left join sapsr3.lfa1 c on c.mandt='168' and c.lifnr=b.lifnr
            left join sapsr3.mch1 d on d.mandt='168' and d.matnr=a.matnr and d.charg=a.charg
          order by a.matkl,a.matnr,a.budat,a.charg
    "
    @rows = Sapdb.find_by_sql [sql, params[:aufnr]]
  end
  
  def query
    @qacode = []
    unless params[:barcode].blank? and params[:aufnr].blank? and params[:matnr].blank? and params[:cycle].blank?
      @qacode = Qacode.where("qrcode like '%#{params[:barcode]}%'")
                     .where("aufnr like '%#{params[:aufnr]}%'")
                     .where("cycle like '%#{params[:cycle]}%'")
                     .where("matnr like '%#{params[:matnr]}%'")		
    end
  end

  def edit
  end

  def create
    @qacode = Qacode.new(qacode_params)
    @qacode.save
    respond_with(@qacode)
  end

  def update
    @qacode.update(qacode_params)
    respond_with(@qacode)
  end

  def destroy
    @qacode.destroy
    respond_with(@qacode)
  end

  private
    def set_qacode
      @qacode = Qacode.find(params[:id])
    end

    def qacode_params
      params.require(:qacode).permit(:qrcode, :aufnr, :matnr, :muser, :cycle)
    end
end
