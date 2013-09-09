# This migration comes from rglossa (originally 20130424025423)
class AddEncodingToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :encoding, :string, default: 'utf-8'
  end
end
