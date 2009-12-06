class CreateCorpus < ActiveRecord::Migration
  def self.up
    create_table :corpora do |t|
      t.string :name, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :corpus
  end
end
