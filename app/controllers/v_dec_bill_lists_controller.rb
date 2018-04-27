class VDecBillListsController < ApplicationController
  before_action :set_v_dec_bill_list, only: [:show]

  respond_to :html

  def index
    @page = (params[:page] || 1).to_i
    entry_id = params[:entry_id] || ''
    ems_list_no = params[:ems_list_no] || ''
    dn_no = params[:dn_no] || ''
    cop_g_no = params[:cop_g_no] || ''
    order_no = params[:order_no] || ''
    ref_no = params[:ref_no] || ''

    @v_dec_bill_lists = Array.new

    unless entry_id.empty? and ems_list_no.empty? and dn_no.empty? and order_no.empty? and ref_no.empty? and cop_g_no.empty?
      @v_dec_bill_lists = VDecBillList
                              .where("entry_id like '%#{entry_id}%'")
                              .where("ems_list_no like '%#{ems_list_no}%'")
                              .where("dn_no like '%#{dn_no}%'")
                              .where("order_no like '%#{order_no}%'")
                              .where("ref_no like '%#{ref_no}%'")
                              .where("cop_g_no like '%#{cop_g_no}%'")
                              .page(@page)
    end
    respond_with(@v_dec_bill_lists)
  end

  def show
    respond_with(@v_dec_bill_list)
  end

  private
  def set_v_dec_bill_list
    @v_dec_bill_list = VDecBillList.find(params[:id])
  end

  def v_dec_bill_list_params
    params[:v_dec_bill_list]
  end
end
