class CreateCorpora < ActiveRecord::Migration
  def up
    create_table :corpora do |t|
      t.string :name, null: false
      t.integer :default_max_hits  # it might be a good idea to set this if the corpus is very big

      t.timestamps
    end

    Corpus.create_translation_table!(name: :string)
  end

  def down
    drop_table :corpora
    Corpus.drop_translation_table!
  end
end
