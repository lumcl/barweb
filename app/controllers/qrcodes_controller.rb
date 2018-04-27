class QrcodesController < ApplicationController
  before_action :set_qrcode, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @page = (params[:page] || 1).to_i
    unless params[:qrcode].blank? and params[:aufnr].blank? and params[:matnr].blank?
      @qrcodes = Qrcode
                     .where("qrcode like '%#{params[:qrcode]}%'")
                     .where("aufnr like '%#{params[:aufnr]}%'")
                     .where("matnr like '%#{params[:matnr]}%'")
                     .order(qrcode: :asc)
                     .page(@page)
      @total_count = @qrcodes.total_count
    else
      @qrcodes = Array.new
    end

    respond_with(@qrcodes)
  end

  def show
    respond_with(@qrcode)
  end

  def new
    @qrcode = Qrcode.new
    respond_with(@qrcode)
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
      sql = 'select count(*) counter, nvl(max(length(qrcode)),0) code_length from qrcode.qrcode where aufnr = ?'
      rows = Qrcode.find_by_sql [sql, list.first.aufnr]
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
      sql = 'select count(*) counter, nvl(max(length(qrcode)),0) code_length from qrcode.qrcode where matnr=? and aufnr = ?'
      rows = Qrcode.find_by_sql [sql,list.first.matnr, list.first.aufnr]
      render js: "
             $('#matnr').val('#{list.first.matnr}');
             $('#aufnr').val('#{list.first.aufnr}');
             $('#counter').val('#{rows.first.counter}');
             $('#code_length').val('#{rows.first.code_length}');
             "
    end
  end

  def process_barcode
    if params[:code_length].to_i > 0 and params[:qrcode].length != params[:code_length].to_i
      render js: "
        document.getElementById('dacuo').play();
        $('#status').html('<h1>#{params[:qrcode]} - 條碼長度不符! <h1/><br/>');
              "
    else
      begin
        @qrcode = Qrcode.create!(
            {
                qrcode: params[:qrcode],
                aufnr: params[:aufnr],
                matnr: params[:matnr],
                muser: request.ip
            }
        )
        counter = Qrcode.where(aufnr: params[:aufnr]).count
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
    qrl = Qrcode.where("aufnr=? and matnr=?", params[:aufnr],params[:matnr])
    #qrl = Qrcode.where("matnr=?", params[:matnr])
    if params[:code_length].to_i >= 0
      if params[:counter].to_i == 0
        if qrl.empty?
          @qrcode = Qrcode.create!(
              {
                  qrcode: params[:qrcode],
                  aufnr: params[:aufnr],
                  matnr: params[:matnr],
                  muser: request.ip
              }
          )
        else
          if qrl.first.matnr.eql? params[:matnr] and !qrl.first.aufnr.eql? params[:aufnr]
            @qrcode = Qrcode.create!(
                {
                    qrcode: qrl.first.qrcode,
                    aufnr: params[:aufnr],
                    matnr: params[:matnr],
                    muser: request.ip
                }
            )
 #         else
 #           @qrcode = Qrcode.create!(
 #               {
 #                   qrcode: params[:qrcode],
 #                   aufnr: params[:aufnr],
 #                   matnr: params[:matnr],
 #                   muser: request.ip
 #               }
 #           )
          end
        end
        counter = Qrcode.where(aufnr: params[:aufnr]).count
        code_length_str = ''
        code_length_str = "$('#code_length').val('#{params[:qrcode].length}');" if params[:code_length].to_i == 0
        render js: "
        $('#status').html('<h1>#{params[:qrcode]} -#{qrl.first.matnr}.eql? #{params[:matnr]} - #{qrl.first.aufnr} - 條碼新增成功! <h1/><br/>');
        $('#counter').val('#{counter}');
        #{code_length_str};
                 "
      else
        status_s = ''
        if qrl.empty?
          #qrla = Qrcode.where("aufnr=? and matnr=?", params[:aufnr],params[:matnr])
        else
            if qrl.first.qrcode.eql? params[:qrcode]
              if qrl.first.matnr.eql? params[:matnr] and !qrl.first.aufnr.eql? params[:aufnr]
                @qrcode = Qrcode.create!(
                    {
                        qrcode: qrl.first.qrcode,
                        aufnr: params[:aufnr],
                        matnr: params[:matnr],
                        muser: request.ip
                    }
                )
              end
              status_s = "$('#status').html('<h1>#{params[:qrcode]} - 條碼正確! <h1/><br/>');"
            else
              #status_s = "$('#status').html('<h1>#{qrlist.first.qrcode} - #{params[:aufnr]} - #{params[:matnr]} - #{params[:qrcode]} - 1條碼長度不符! <h1/><br/>');"
              status_s = "$('#status').html('<h1>#{params[:qrcode]} - 條碼不符! <h1/><br/>');"
            end
        end
        render js: "
        document.getElementById('dacuo').play();
        #{status_s}
               "
      end
    else
      render js: "
        document.getElementById('dacuo').play();
        $('#status').html('<h1> #{params[:counter]} - #{params[:qrcode]} - 條碼不能为空! <h1/><br/>');
              "
    end
  end

  def process_barcode_rule
    message = ""
    suc = 0
    qr = Qrcode.where("qrcode=?",params[:qrcode])
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
          suc = 0
          message = "
                     document.getElementById('dacuo').play();
                     $('#status').html('<h1 style=color:red>#{new_qc} != #{qc} - 规则不符! <h1/><br/>');
                    "
          break
        else
          if qr.empty?
            message = "$('#status').html('<h1>#{new_qc} == #{qc} - 條碼正確!  <h1/><br/>');"
            suc = 1
          else
            message = "
                       document.getElementById('dacuo').play();
                       $('#status').html('<h1 style=color:red>#{new_qc} 條碼重複! <h1/><br/>');
                       "
            suc = 0
          end
        end
        i = i + 1
      }

      if (suc == 1)
        @qrcode = Qrcode.create!(
          {
              qrcode: params[:qrcode],
              aufnr: params[:aufnr],
              matnr: params[:matnr],
              muser: request.ip
          }
        )
      end
    end
    render js:  "#{message}"
  end

  def read_barcode

  end

  def read_barcode_repeat

  end

  def read_barcode_rule

  end

  def create
    @qrcode = Qrcode.new(qrcode_params)
    @qrcode.save
    respond_with(@qrcode)
  end

  def update
    @qrcode.update(qrcode_params)
    respond_with(@qrcode)
  end

  def destroy
    @qrcode.destroy
    respond_with(@qrcode)
  end

  private
  def set_qrcode
    @qrcode = Qrcode.find(params[:id])
  end

  def qrcode_params
    params.require(:qrcode).permit(:qrcode, :aufnr, :matnr, :muser, :code1)
  end

end
