class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.string :query, :null => false
      t.boolean :is_regexp
      t.string :search_within
      t.integer :page_size
      t.boolean :randomize
      t.boolean :skip_total
      t.string :context_type
      t.integer :left_context
      t.integer :right_context

      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
