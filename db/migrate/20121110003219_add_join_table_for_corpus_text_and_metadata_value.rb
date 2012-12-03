class AddJoinTableForCorpusTextAndMetadataValue < ActiveRecord::Migration
  def change
    create_table :rglossa_corpus_texts_metadata_values do |t|
      t.belongs_to :rglossa_corpus_text
      t.belongs_to :rglossa_metadata_value
    end
  end
end
