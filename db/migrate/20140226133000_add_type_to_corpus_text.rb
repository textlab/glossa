class AddTypeToCorpusText < ActiveRecord::Migration
  def change
    add_column :rglossa_corpus_texts, :type, :string
  end
end
