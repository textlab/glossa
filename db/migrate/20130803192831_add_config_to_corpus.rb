class AddConfigToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :config, :text
  end
end
