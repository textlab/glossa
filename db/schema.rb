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

ActiveRecord::Schema.define(:version => 20121023142202) do

  create_table "corpora", :force => true do |t|
    t.string   "name",             :null => false
    t.integer  "default_max_hits"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "corpus_texts", :force => true do |t|
    t.integer  "language_config_id"
    t.string   "uri"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "corpus_translations", :force => true do |t|
    t.integer  "corpus_id"
    t.string   "locale"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "corpus_translations", ["corpus_id"], :name => "index_corpus_translations_on_corpus_id"
  add_index "corpus_translations", ["locale"], :name => "index_corpus_translations_on_locale"

  create_table "deleted_hits", :force => true do |t|
    t.integer  "search_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "metadata_categories", :force => true do |t|
    t.integer  "corpus_id"
    t.string   "name",          :null => false
    t.string   "category_type", :null => false
    t.string   "value_type",    :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "metadata_category_translations", :force => true do |t|
    t.integer  "metadata_category_id"
    t.string   "locale"
    t.string   "name"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "metadata_category_translations", ["locale"], :name => "index_metadata_category_translations_on_locale"
  add_index "metadata_category_translations", ["metadata_category_id"], :name => "index_40250a4bb167b9603d1cdfaab50036c15b217979"

  create_table "metadata_values", :force => true do |t|
    t.integer "metadata_category_id"
    t.string  "type"
    t.text    "text_value"
    t.integer "integer_value"
    t.boolean "boolean_value"
  end

  create_table "searches", :force => true do |t|
    t.integer  "owner_id"
    t.text     "queries",            :null => false
    t.text     "search_options"
    t.text     "metadata_selection"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
