# This migration comes from rglossa (originally 20130803192831)
class AddConfigToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :config, :text
  end
end
