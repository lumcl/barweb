class IebBomsController < ApplicationController
  before_action :set_ieb_bom, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    matnr = params[:matnr] || ''
    vernr = params[:vernr] || ''
    rstat = params[:rstat] || ''
    @page = (params[:page] || 1).to_i

    if matnr.empty? and vernr.empty? and rstat.empty?
      @ieb_boms = IebBom.where(rstat: 1).order(matnr: :asc, vernr: :asc).page(@page)
    else
      @ieb_boms = IebBom.where("matnr like '%#{matnr}%'")
                      .where("vernr like '%#{vernr}%'")
                      .where("rstat like '%#{rstat}%'")
                      .order(matnr: :asc, vernr: :asc)
                      .page(@page)
    end

    respond_with(@ieb_boms)
  end

  def show
    sql = 'SELECT ID,CONNR,MATNR,VERNR,IDNRK,WERKS,MENGE,MEINS,AUSCH,DLRAT,DEUOM,CUTXT,NETKG,CBTYP,CBSEQ,HSCODE,HSTXT,MATKL,MAKTX FROM IEB_BOMS_V1 WHERE ID = ?'
    @ieb_bom_lines = IebBom.find_by_sql [sql, @ieb_bom.id]
    respond_with(@ieb_bom)
  end

  def upload_bom_to_ygt
    if params[:ids]
      params[:ids].each do |bom_id|
        flash[:notice] = YgtPreEms3OrgBom.upload_boms(bom_id)
      end
    end

    redirect_to ieb_boms_url
  end

  def version_matrix
    sql = '
      SELECT B.CONNR, B.MATNR, B.VERNR,  E.DEUOM, B.ID,
             F.CUTXT, C.CBTYP, C.CBSEQ, E.HSCODE, E.HSTXT,SUM(B.MENGE * C.DLRAT) DLQTY, SUM(B.AUSCH) AUSCH
        FROM (  SELECT A.CONNR, A.MATNR, A.VERNR, B.IDNRK, B.WERKS, A.ID,
                       SUM (B.MENGE) MENGE, SUM (B.AUSCH) AUSCH
                  FROM IEB_BOMS A, IEB_BOM_LINES B
                 WHERE     B.IEB_BOM_ID = A.ID
                       AND MATNR = ?
                       AND B.WERKS IN (?)
              GROUP BY A.CONNR, A.MATNR, A.VERNR, B.IDNRK, B.WERKS, A.ID) B,
             SAP_ZIEBA003 C,
             SAP_ZIEBC001 E,
             SAP_ZIEBB002 F
       WHERE     C.CONNR(+) = B.CONNR
             AND C.MATNR(+) = B.IDNRK
             AND E.CONNR(+) = C.CONNR
             AND E.CBTYP(+) = C.CBTYP
             AND E.CBSEQ(+) = C.CBSEQ
             AND F.CUUOM(+) = E.DEUOM
             GROUP BY B.CONNR, B.MATNR, B.VERNR,  E.DEUOM,
             F.CUTXT, C.CBTYP, C.CBSEQ, E.HSCODE, E.HSTXT, B.ID
             ORDER BY HSTXT, B.VERNR
    '
    @rows = IebBom.find_by_sql [sql, params[:matnr], '381A']

    @cbseqs = Array.new
    @versions = Array.new
    @bom_ids = Hash.new
    @cbseq_datas = Hash.new
    @values = Hash.new

    @rows.each do |row|
      @cbseqs.append row.cbseq unless @cbseqs.include?(row.cbseq)
      @versions.append row.vernr unless @versions.include?(row.vernr)
      @bom_ids[row.vernr] = row.id unless @bom_ids.include?(row.id)
      @cbseq_datas[row.cbseq] = [row.hstxt, row.hscode, row.cbseq, row.cutxt] unless @cbseq_datas.include?(row.cbseq)
      @values["#{row.cbseq}_#{row.vernr}"] = row.dlqty
    end

  end

  def new
    @ieb_bom = IebBom.new
    respond_with(@ieb_bom)
  end

  def edit
  end

  def create
    @ieb_bom = IebBom.new(ieb_bom_params)
    @ieb_bom.save
    respond_with(@ieb_bom)
  end

  def update
    @ieb_bom.update(ieb_bom_params)
    respond_with(@ieb_bom)
  end

  def destroy
    @ieb_bom.destroy
    respond_with(@ieb_bom)
  end

  private
  def set_ieb_bom
    @ieb_bom = IebBom.find(params[:id])
  end

  def ieb_bom_params
    params.require(:ieb_bom).permit(:connr, :matnr, :vernr, :rstat, :menge, :sap_updated, :sap_updated_at, :ygt_updated, :ygt_updated_at, :home_made_parts)
  end
end
