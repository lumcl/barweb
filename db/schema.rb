# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161209063355) do

  create_table "pcbmains_bak", force: true do |t|
    t.string   "pcblabel",   limit: 200
    t.string   "panellabel", limit: 200
    t.string   "clientip",   limit: 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "prodrules", force: true do |t|
    t.string   "qrcode"
    t.string   "rule"
    t.string   "matnr"
    t.string   "muser"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "prodrules", ["qrcode"], name: "index_prodrules_on_qrcode"

  create_table "qacodes", force: true do |t|
    t.string   "qrcode"
    t.string   "aufnr"
    t.string   "matnr"
    t.string   "muser"
    t.string   "cycle"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qbarcodes", force: true do |t|
    t.string   "qrcode"
    t.string   "aufnr"
    t.string   "matnr"
    t.string   "muser"
    t.string   "rule"
    t.string   "same"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "qrcode", force: true do |t|
    t.string   "qrcode"
    t.string   "aufnr"
    t.string   "matnr"
    t.string   "muser"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code1"
    t.string   "cycle"
  end

  add_index "qrcode", ["aufnr"], name: "qrcode_index"
  add_index "qrcode", ["qrcode"], name: "index_qrcode_on_qrcode"

  create_table "qrcode_bk", id: false, force: true do |t|
    t.integer  "id",         precision: 38, scale: 0, null: false
    t.string   "qrcode"
    t.string   "aufnr"
    t.string   "matnr"
    t.string   "muser"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_info", id: false, force: true do |t|
    t.string "user_ip",   limit: 50
    t.string "user_mac",  limit: 50
    t.string "user_name", limit: 50
  end

  create_table "users", force: true do |t|
    t.string   "email",                                           default: "", null: false
    t.string   "encrypted_password",                              default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          precision: 38, scale: 0, default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "i_users_reset_password_token", unique: true

  create_table "zichan_pddts", id: false, force: true do |t|
    t.string   "uuid",       null: false
    t.string   "qrcode",     null: false
    t.string   "period",     null: false
    t.string   "user_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "zichan_pds", primary_key: "uuid", force: true do |t|
    t.string   "qrcode",     null: false
    t.string   "period",     null: false
    t.string   "equipment"
    t.string   "po_date"
    t.string   "supplier"
    t.string   "warranty"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "company"
    t.string   "name1"
    t.string   "user_ip"
  end

  add_index "zichan_pds", ["qrcode", "period"], name: "i_zichan_pds_qrcode_period"

  create_table "zichan_pds_20170629", id: false, force: true do |t|
    t.string   "qrcode",     null: false
    t.string   "period",     null: false
    t.string   "equipment"
    t.string   "po_date"
    t.string   "supplier"
    t.string   "warranty"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid",       null: false
    t.string   "company"
    t.string   "name1"
    t.string   "user_ip"
  end

end
