# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091223175749) do

  create_table "aligned_segments", :id => false, :force => true do |t|
    t.integer "segment_id",         :null => false
    t.integer "aligned_segment_id", :null => false
  end

  create_table "corpora", :force => true do |t|
    t.string   "name",             :null => false
    t.integer  "default_max_hits"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corpora_language_configs", :force => true do |t|
    t.integer  "corpus_id",          :null => false
    t.integer  "language_config_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corpora_metadata_categories", :id => false, :force => true do |t|
    t.integer "corpus_id",            :null => false
    t.integer "metadata_category_id", :null => false
  end

  create_table "corpus_texts", :force => true do |t|
    t.integer  "language_config_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corpus_texts_subcorpora", :id => false, :force => true do |t|
    t.integer "corpus_text_id", :null => false
    t.integer "subcorpus_id",   :null => false
  end

  create_table "language_config_types", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "tagger"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "language_configs", :force => true do |t|
    t.integer  "corpus_id"
    t.integer  "language_config_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metadata_categories", :force => true do |t|
    t.string   "name",       :null => false
    t.string   "fieldtype",  :null => false
    t.string   "selector"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "metadata_values", :force => true do |t|
    t.integer "metadata_category_id"
    t.integer "corpus_text_id"
    t.string  "type"
    t.text    "text_value"
    t.integer "integer_value"
    t.date    "date_value"
    t.boolean "boolean_value"
  end

  create_table "preference_collections", :force => true do |t|
    t.integer  "user_id"
    t.integer  "page_size"
    t.string   "context_type"
    t.integer  "left_context"
    t.integer  "right_context"
    t.integer  "skip_total"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", :force => true do |t|
    t.integer  "user_id"
    t.text     "queries",            :null => false
    t.text     "search_options"
    t.text     "metadata_selection"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "segments", :force => true do |t|
    t.integer  "corpus_text_id"
    t.string   "s_id"
    t.text     "contents",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subcorpora", :force => true do |t|
    t.integer  "corpus_id"
    t.integer  "user_id"
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "username",                           :null => false
    t.string   "email",                              :null => false
    t.string   "crypted_password",                   :null => false
    t.string   "password_salt",                      :null => false
    t.string   "persistence_token",                  :null => false
    t.string   "single_access_token",                :null => false
    t.string   "perishable_token",                   :null => false
    t.integer  "login_count",         :default => 0, :null => false
    t.integer  "failed_login_count",  :default => 0, :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end