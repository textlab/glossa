class CreateCorpusMetadataCategories < ActiveRecord::Migration
  def self.up
    create_table :corpora_metadata_categories do |t|
      t.integer :corpus_id, :null => false
      t.integer :metadata_category_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :corpora_metadata_categories
  end
end
