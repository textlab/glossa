class CreateCorporaMetadataCategories < ActiveRecord::Migration
  def self.up
    create_table :corpora_metadata_categories, :id => false do |t|
      t.integer :corpus_id, :null => false
      t.integer :metadata_category_id, :null => false
    end
  end

  def self.down
    drop_table :corpora_metadata_categories
  end
end
