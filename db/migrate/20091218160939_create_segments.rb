class CreateSegments < ActiveRecord::Migration
  def self.up
    create_table :segments do |t|
      t.integer :corpus_text_id
      t.string :s_id
      t.text :contents, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :segments
  end
end
