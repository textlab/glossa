class AddCorpusPartCountsToSearch < ActiveRecord::Migration
  def change
    add_column :rglossa_searches, :corpus_part_counts, :text, null: false
  end
end
