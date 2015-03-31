# This migration comes from rglossa (originally 20140908111628)
class CreateRglossaMediaFiles < ActiveRecord::Migration
  def up
    create_table :rglossa_media_files do |t|
      t.belongs_to :corpus,      null: false
      t.integer :line_key_begin, null: false
      t.integer :line_key_end,   null: false
      t.string :basename,        null: false
    end
  end

  def down
    drop_table :rglossa_media_files
  end
end
