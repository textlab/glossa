class AddJoinTableForCorpusTextAndMetadataValue < ActiveRecord::Migration
  def change
    create_table :rglossa_corpus_texts_metadata_values do |t|
      t.belongs_to :rglossa_corpus_text, null: false
      t.belongs_to :rglossa_metadata_value, null: false
    end
  end
end
