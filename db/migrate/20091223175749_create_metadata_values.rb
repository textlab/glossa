class CreateMetadataValues < ActiveRecord::Migration
  def self.up
    create_table :metadata_values do |t|
      t.integer :corpus_text_id
      t.integer :metadata_category_id
      t.string :type
      t.text :text_value
      t.integer :integer_value
      t.boolean :boolean_value
    end
  end

  def self.down
    drop_table :metadata_values
  end
end
