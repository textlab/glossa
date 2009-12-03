class CreateCorpus < ActiveRecord::Migration
  def self.up
    create_table :corpus do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :corpus
  end
end
