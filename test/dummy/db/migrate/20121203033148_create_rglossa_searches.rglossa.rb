# This migration comes from rglossa (originally 20091206173444)
class CreateRglossaSearches < ActiveRecord::Migration
  def change
    create_table :rglossa_searches do |t|
      t.integer :user_id
      t.string :type
      t.text :queries, null: false
      t.text :search_options
      t.text :metadata_selection

      t.timestamps
    end
  end
end