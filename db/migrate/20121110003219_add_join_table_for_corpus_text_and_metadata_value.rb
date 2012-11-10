class AddJoinTableForCorpusTextAndMetadataValue < ActiveRecord::Migration
  def change
    create_table :corpus_texts_metadata_values do |t|
      t.belongs_to :corpus_text
      t.belongs_to :metadata_value
    end
  end
end
