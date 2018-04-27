# DROP VIEW SAP.V_DEC_BILL_LIST;
#
# /* Formatted on 2015/5/12 14:53:34 (QP5 v5.256.13226.35510) */
# CREATE OR REPLACE FORCE VIEW sap.v_dec_bill_list
# (
#    ems_no,
#    ems_list_no,
#    i_e_flag,
#    entry_id,
#    list_declare_date,
#    id,
#    list_no,
#    list_g_no,
#    em_g_no,
#    exg_version,
#    cop_g_no,
#    g_name,
#    g_model,
#    country_code,
#    country_na,
#    qty,
#    unit,
#    unit_name,
#    dec_price,
#    dec_total,
#    curr,
#    curr_symb,
#    custom_g_no,
#    order_no,
#    ent_qty,
#    batch_no,
#    dn_no,
#    dn_line,
#    ref_no,
#    trade_date,
#    package_no,
#    gross_wt,
#    net_wt
# )
# AS
#    SELECT h.ems_no,
#           h.ems_list_no,
#           bs.i_e_flag,
#           gwgl.fun_get_ie_entry_id (bs.list_no, bs.i_e_flag) entry_id,
#           TO_CHAR (h.list_declare_date, 'YYYYMMDD') list_declare_date,
#           (a.list_no || '_' || a.list_g_no) id,
#           a.list_no,
#           a.list_g_no,
#           a.em_g_no,
#           a.exg_version,
#           a.cop_g_no,
#           a.g_name,
#           a.g_model,
#           a.country_code,
#           pcnt.country_na,
#           a.qty,
#           a.unit,
#           pu.unit_name,
#           a.dec_price,
#           a.dec_total,
#           a.curr,
#           pcurr.curr_symb,
#           sl.custom_g_no,
#           sl.order_no,
#           sl.remark1 ent_qty,
#           sl.remark2 batch_no,
#           sl.remark3 dn_no,
#           sl.remark4 dn_line,
#           sl.file_no ref_no,
#           sl.trade_date,
#           sl.package_no,                                                  --件数
#           sl.gross_wt,                                                    --毛重
#           sl.net_wt                                                       --净重
#      FROM offline_dec.dec_bill_list a
#           JOIN offline_dec.dec_bill_head h ON a.list_no = h.list_no
#           JOIN offline_dec.dec_bill_status bs ON h.list_no = bs.list_no
#           JOIN sic.ep_dec_bill_list sl
#              ON sl.list_no = bs.temp_seq_no AND a.list_g_no = sl.list_g_no
#           JOIN sic.ep_dec_bill_head se ON se.list_no = bs.temp_seq_no
#           LEFT JOIN pub_para.curr pcurr ON a.curr = pcurr.curr_code
#           LEFT JOIN pub_para.country pcnt ON a.country_code = pcnt.country_co
#           LEFT JOIN pub_para.unit pu ON a.unit = pu.unit_code
#     WHERE NVL (se.isvalid, '1') = '1';
#
# ALTER VIEW SAP.V_DEC_BILL_LIST
#  ADD PRIMARY KEY
#   (ID)
#   DISABLE;

class VDecBillList < ActiveRecord::Base
  establish_connection :ygtdb
  self.table_name = 'sap.v_dec_bill_list'

end
