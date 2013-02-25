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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130222171020) do

  create_table "rglossa_corpora", :force => true do |t|
    t.string   "name",             :null => false
    t.string   "short_name"
    t.integer  "default_max_hits"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "rglossa_corpus_texts", :force => true do |t|
    t.integer  "startpos",   :limit => 8
    t.integer  "endpos",     :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "rglossa_corpus_texts_metadata_values", :force => true do |t|
    t.integer "rglossa_corpus_text_id"
    t.integer "rglossa_metadata_value_id"
  end

  create_table "rglossa_corpus_translations", :force => true do |t|
    t.integer  "rglossa_corpus_id"
    t.string   "locale"
    t.string   "name"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "rglossa_corpus_translations", ["locale"], :name => "index_rglossa_corpus_translations_on_locale"
  add_index "rglossa_corpus_translations", ["rglossa_corpus_id"], :name => "index_rglossa_corpus_translations_on_rglossa_corpus_id"

  create_table "rglossa_deleted_hits", :force => true do |t|
    t.integer  "search_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "rglossa_metadata_categories", :force => true do |t|
    t.integer  "corpus_id"
    t.string   "name",          :null => false
    t.string   "category_type", :null => false
    t.string   "value_type",    :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "rglossa_metadata_category_translations", :force => true do |t|
    t.integer  "rglossa_metadata_category_id"
    t.string   "locale"
    t.string   "name"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
  end

  add_index "rglossa_metadata_category_translations", ["locale"], :name => "index_rglossa_metadata_category_translations_on_locale"
  add_index "rglossa_metadata_category_translations", ["rglossa_metadata_category_id"], :name => "index_e158ce1e8d13553f5fb5f8b2393ea60d7b09f133"

  create_table "rglossa_metadata_values", :force => true do |t|
    t.integer "metadata_category_id"
    t.string  "type"
    t.text    "text_value"
    t.integer "integer_value"
    t.boolean "boolean_value"
  end

  create_table "rglossa_searches", :force => true do |t|
    t.integer  "user_id"
    t.string   "type"
    t.text     "queries",            :null => false
    t.text     "search_options"
    t.text     "metadata_value_ids"
    t.integer  "num_hits"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

end
