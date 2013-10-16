# This migration comes from rglossa (originally 20131015142228)
class AddCorpusPartCountsToSearch < ActiveRecord::Migration
  def change
    add_column :rglossa_searches, :corpus_part_counts, :text, null: false, default: ''
  end
end
