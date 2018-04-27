class IebMsegsController < ApplicationController
  before_action :set_ieb_mseg, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @ieb_msegs = IebMseg.all
    respond_with(@ieb_msegs)
  end

  def show
    respond_with(@ieb_mseg)
  end

  def new
    @ieb_mseg = IebMseg.new
    respond_with(@ieb_mseg)
  end

  def edit
  end

  def create
    @ieb_mseg = IebMseg.new(ieb_mseg_params)
    @ieb_mseg.save
    respond_with(@ieb_mseg)
  end

  def update
    @ieb_mseg.update(ieb_mseg_params)
    respond_with(@ieb_mseg)
  end

  def destroy
    @ieb_mseg.destroy
    respond_with(@ieb_mseg)
  end

  def zindex_v3

    return @ieb_msegs = Array.new unless params[:query]

    lifnr = params[:lifnr] || ''
    str_budat = params[:str_budat] || ''
    end_budat = params[:end_budat] || ''
    closn = params[:closn] || ''
    cbseq = params[:cbseq] || ''

    @closns = Hash.new

    if lifnr.empty? or str_budat.empty? or end_budat.empty? or closn.empty?
      flash[:error] = '供應商代號, 開始交易日期, 結束交易日期必須填寫正確'
      @ieb_msegs = Array.new
    else
      sql = "SELECT B.CBSEQ, B.CLOIM
          FROM SAPSR3.ZIEBI005@SAPP A, SAPSR3.ZIEBI006@SAPP B
         WHERE     B.MANDT = A.MANDT
               AND A.BNAREA = B.BNAREA
               AND A.BUKRS = B.BUKRS
               AND B.CLOSN = A.CLOSN
               AND B.CBTYP = 'R'
               AND A.MANDT = '168'
               AND A.BNAREA = ?
               AND A.BUKRS = ?
               AND A.LIFNR = ?
               AND A.CLOSN = ?"
      rows = IebMseg.find_by_sql [sql, Figaro.env.bnarea, Figaro.env.bukrs, lifnr, closn]

      if rows.empty?
        flash[:error] = '關封號錯誤或者系統不存在!!!'
        @ieb_msegs = Array.new
      else
        rows.each do |row|
          @closns[row.cbseq] = row.cloim unless @closns.key?(row.cbseq)
        end

        sql = "SELECT /*+ DRIVING_SITE(B) */
            A.ID, A.BUDAT, A.MJAHR, A.MBLNR, A.ZEILE, A.MATNR, A.CHARG, A.MENGE,
             A.MEINS, A.WRBTR, A.WAERS, A.CBSEQ, A.APMNG, B.HSTXT, C.CUTXT,
             (D.NETKG * MENGE) WEIGHT, NVL(E.FSRAT,0) FSRAT
        FROM IEB_MSEGS A, SAP_ZIEBC001 B, SAP_ZIEBB002 C, SAP_MARA D,
             SAP_ZIEBA003 E
       WHERE     A.PARVW = 'V3'
             AND NVL(A.IMPNR,' ') = ' '
             AND B.CONNR(+) = A.CONNR
             AND B.CBTYP(+) = A.CBTYP
             AND B.CBSEQ(+) = A.CBSEQ
             AND C.CUUOM(+) = A.DEUOM
             AND D.MATNR(+) = A.MATNR
             AND E.CONNR(+) = A.CONNR
             AND E.CBTYP(+) = A.CBTYP
             AND E.CBSEQ(+) = A.CBSEQ
             AND E.MATNR(+) = A.MATNR
             AND A.LIFNR = ?
             AND A.BUDAT BETWEEN ? AND ?
             AND A.CBSEQ LIKE '%#{cbseq}%'
        ORDER BY A.BUDAT, A.MJAHR, A.MBLNR, A.ZEILE"
        @ieb_msegs = IebMseg.find_by_sql [sql, lifnr, str_budat, end_budat]
      end
    end

  end

  def zcreate_v3
    flash[:error] = IebMseg.zcreate_v3(params)
    redirect_to zindex_v3_ieb_msegs_url
  end

  private
  def set_ieb_mseg
    @ieb_mseg = IebMseg.find(params[:id])
  end

  def ieb_mseg_params
    params.require(:ieb_mseg).permit(:mjahr, :mblnr, :zeile, :vgart, :blart, :bwart, :budat, :cpudt, :cputm, :matnr, :werks, :lgort, :charg, :menge, :meins, :dmbtr, :waers, :parvw, :lifnr, :ebeln, :ebelp, :xblnr, :belnr_ap, :buzei_ap, :gjahr_ap, :guinr, :lifnr_sto, :ebeln_sto, :ebelp_sto, :belnr_sto, :buzei_sto, :gjahr_sto, :kunnr, :kunnr_dlv, :vbeln_dn, :posnr_dn, :vbeln_so, :posnr_so, :vbeln_inv, :posnr_inv, :aufnr, :rsnum, :rspos, :connr, :cbseq, :apmng, :dlrat, :cutxt, :impnr, :impim, :expnr, :expim, :dlfnr, :decdt, :belnr_pay, :buzei_pay, :gjahr_pay, :rstat)
  end
end
