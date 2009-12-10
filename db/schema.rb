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

ActiveRecord::Schema.define(:version => 20091210093443) do

  create_table "corpora", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corpora_metadata_categories", :force => true do |t|
    t.integer  "corpus_id",            :null => false
    t.integer  "metadata_category_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corpus_texts", :force => true do |t|
    t.integer  "corpus_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "language_configs", :force => true do |t|
    t.integer  "corpus_id"
    t.string   "name",       :null => false
    t.string   "tagger"
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

  create_table "searches", :force => true do |t|
    t.string   "query",         :null => false
    t.boolean  "is_regexp"
    t.string   "search_within"
    t.integer  "page_size"
    t.boolean  "randomize"
    t.boolean  "skip_total"
    t.string   "context_type"
    t.integer  "left_context"
    t.integer  "right_context"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subcorpora", :force => true do |t|
    t.integer  "corpus_id"
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
