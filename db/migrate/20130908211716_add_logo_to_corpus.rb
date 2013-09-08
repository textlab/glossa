class AddLogoToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :logo, :string
  end
end
