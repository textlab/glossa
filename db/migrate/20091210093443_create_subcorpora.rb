class CreateSubcorpora < ActiveRecord::Migration
  def self.up
    create_table :subcorpora do |t|
      t.integer :corpus_id
      t.string :name, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :subcorpora
  end
end
