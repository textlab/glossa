class AddEncodingToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :encoding, :string, default: 'utf-8'
  end
end
