class QbarcodesController < ApplicationController
  before_action :set_qbarcode, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @page = (params[:page] || 1).to_i
    unless params[:qbarcodes].blank? and params[:aufnr].blank? and params[:matnr].blank?
      @qbarcodes = Qbarcode
                     .where("qrcode like '%#{params[:qrcode]}%'")
                     .where("aufnr like '%#{params[:aufnr]}%'")
                     .where("matnr like '%#{params[:matnr]}%'")
                     .order(qrcode: :asc)
                     .page(@page)
      @total_count = @qbarcodes.total_count
    else
      @qbarcodes = Array.new
    end

    respond_with(@qbarcodes)
  end

  def show
    respond_with(@qbarcodes)
  end

  def new
    @qbarcodes = Qbarcode.new
    respond_with(@qbarcodes)
  end

  def edit
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
      sql = 'select count(*) counter, nvl(max(length(qrcode)),0) code_length from qrcode.qbarcodes where aufnr = ?'
      rows = Qbarcode.find_by_sql [sql, list.first.aufnr]
      render js: "
             $('#matnr').val('#{list.first.matnr}');
             $('#aufnr').val('#{list.first.aufnr}');
             $('#counter').val('#{rows.first.counter}');
             $('#code_length').val('#{rows.first.code_length}');
             "
    end
  end

  def get_product_order_repeat
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
      sql = 'select count(*) counter, nvl(max(length(qrcode)),0) code_length from qrcode.qbarcodes where matnr=? and aufnr = ?'
      rows = Qbarcode.find_by_sql [sql,list.first.matnr, list.first.aufnr]
      render js: "
             $('#matnr').val('#{list.first.matnr}');
             $('#aufnr').val('#{list.first.aufnr}');
             $('#counter').val('#{rows.first.counter}');
             $('#code_length').val('#{rows.first.code_length}');
             "
    end
  end

  def process_barcode
    if params[:code_length].to_i > 0 and params[:qbarcodes].length != params[:code_length].to_i
      render js: "
        document.getElementById('dacuo').play();
        $('#status').html('<h1>#{params[:qbarcodes]} - 條碼長度不符! <h1/><br/>');
              "
    else
      begin
        @qbarcodes = Qbarcode.create!(
            {
                qrcode: params[:qrcode],
                aufnr: params[:aufnr],
                matnr: params[:matnr],
                muser: request.ip
            }
        )
        counter = Qbarcode.where(aufnr: params[:aufnr]).count
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
        $('#status').html('<h1>#{params[:qrcode]} - 條碼重複! <h1/><br/>');
              "
      end
    end
  end

  def process_barcode_repeat
    message = ""
    @prodrule = Prodrule.where("matnr=?",params[:matnr])
    if @prodrule.empty?
      render js: "
        $('#status').html('<h1>#{params[:qrcode][0]} != #{params[:matnr]} - 规则不存在,请增加 ! <h1/><br/>');
                 "
    else
      i = 0
      ru = @prodrule.first.rule
      qc = @prodrule.first.qrcode
      new_qc = params[:qrcode]
      ru.each_char { |c|
         if (c == '*' and (new_qc[i] != qc[i]))
           message = "$('#status').html('<h1 style=color:red>#{new_qc} != #{qc} - 规则不符! <h1/><br/>');"
           break
         else
           message = "$('#status').html('<h1>#{new_qc} == #{qc} - 规则符合! <h1/><br/>');"
         end
         i = i + 1
      }
      @qbarcodes = Qbarcode.create!(
        {
          qrcode: params[:qrcode],
          aufnr: params[:aufnr],
          matnr: params[:matnr],
          muser: request.ip
        }
      )

 #   qrl = Qbarcode.where("aufnr=? and matnr=?", params[:aufnr],params[:matnr])
 #   if params[:code_length].to_i >= 0
 #     if params[:counter].to_i == 0
 #       if qrl.empty?
 #         @qbarcodes = Qbarcode.create!(
 #             {
 #                 qrcode: params[:qrcode],
 #                 aufnr: params[:aufnr],
 #                 matnr: params[:matnr],
 #                 muser: request.ip
 #             }
 #         )
 #       else
 #         if qrl.first.matnr.eql? params[:matnr] and !qrl.first.aufnr.eql? params[:aufnr]
 #           @qbarcodes = Qbarcode.create!(
 #               {
 #                   qrcode: qrl.first.qrcode,
 #                   aufnr: params[:aufnr],
 #                   matnr: params[:matnr],
 #                   muser: request.ip
 #               }
 #           )
 #         end
 #       end
 #       counter = Qbarcode.where(aufnr: params[:aufnr]).count
 #       code_length_str = ''
 #       code_length_str = "$('#code_length').val('#{params[:qrcode].length}');" if params[:code_length].to_i == 0
 #       render js: "
 #       $('#status').html('<h1>#{params[:qrcode]} - 條碼新增成功! <h1/><br/>');
 #       $('#counter').val('#{counter}');
 #      #{code_length_str};
 #                "
 #     else
 #       status_s = ''
 #       if qrl.empty?

 #       else
 #         if qrl.first.qrcode.eql? params[:qrcode]
 #           if qrl.first.matnr.eql? params[:matnr] and !qrl.first.aufnr.eql? params[:aufnr]
 #             @qbarcodes = Qbarcode.create!(
 #                 {
 #                     qrcode: qrl.first.qrcode,
 #                     aufnr: params[:aufnr],
 #                     matnr: params[:matnr],
 #                     muser: request.ip
 #                 }
 #             )
 #           end
 #           status_s = "$('#status').html('<h1>#{params[:qrcode]} - 條碼正確! <h1/><br/>');"
 #         else
 #           status_s = "$('#status').html('<h1>#{params[:qrcode]} - 條碼不符! <h1/><br/>');"
 #         end
 #       end
 #       render js: "
 #       document.getElementById('dacuo').play();
 #       #{status_s}
 #              "
 #     end
 #   else
 #     render js: "
 #       document.getElementById('dacuo').play();
 #       $('#status').html('<h1> #{params[:counter]} - #{params[:qrcode]} - 條碼不能为空! <h1/><br/>');
 #             "
 #   end
    end
    render js:  "#{message}"
  end

  def read_barcode

  end

  def read_barcode_repeat

  end

  def create
    @qbarcodes = Qbarcode.new(qbarcode_params)
    @qbarcodes.save
    respond_with(@qbarcodes)
  end

  def update
    @qbarcodes.update(qbarcode_params)
    respond_with(@qbarcodes)
  end

  def destroy
    @qbarcodes.destroy
    respond_with(@qbarcodes)
  end

  private
  def set_qbarcode
    @qbarcodes = Qbarcode.find(params[:id])
  end

  def qbarcode_params
    params.require(:qrcode).permit(:qrcode, :aufnr, :matnr, :muser)
  end

end