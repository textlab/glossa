# This migration comes from rglossa (originally 20140715154548)
class AddCorpusShortNameToSearch < ActiveRecord::Migration
  def change
    add_column :rglossa_searches, :corpus_short_name, :string
  end
end
