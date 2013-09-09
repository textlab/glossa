# This migration comes from rglossa (originally 20130908211716)
class AddLogoToCorpus < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :logo, :string
  end
end
