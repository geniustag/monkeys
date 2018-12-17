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

ActiveRecord::Schema.define(version: 20181217023928) do

  create_table "etransactions", force: true do |t|
    t.integer  "player_id"
    t.integer  "address"
    t.string   "efrom"
    t.string   "eto"
    t.string   "amount"
    t.string   "key_price"
    t.text     "extra_info"
    t.string   "token"
    t.string   "tx_hash"
    t.integer  "status"
    t.text     "event_data"
    t.string   "meth"
    t.integer  "parent_id"
    t.integer  "tran_type"
    t.integer  "block_number"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "etransactions", ["address"], name: "index_etransactions_on_address", using: :btree
  add_index "etransactions", ["key_price"], name: "index_etransactions_on_key_price", unique: true, using: :btree
  add_index "etransactions", ["tx_hash"], name: "index_etransactions_on_tx_hash", unique: true, using: :btree

  create_table "games", force: true do |t|
    t.string   "name"
    t.string   "core_address"
    t.string   "player_book_address"
    t.string   "actived_at"
    t.text     "extro"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "keys", force: true do |t|
    t.string   "price"
    t.integer  "game_id"
    t.integer  "pid"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resources", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.integer  "parent_id"
    t.string   "desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resources_roles", force: true do |t|
    t.integer  "resource_id"
    t.integer  "role_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.string   "name_en"
    t.string   "desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles_users", force: true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

end
