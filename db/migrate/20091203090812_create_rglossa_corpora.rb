class CreateRglossaCorpora < ActiveRecord::Migration
  def up
    create_table :rglossa_corpora do |t|
      t.string :name, null: false
      t.integer :default_max_hits  # it might be a good idea to set this if the corpus is very big

      t.timestamps
    end

    Rglossa::Corpus.create_translation_table!(name: :string)
  end

  def down
    drop_table :rglossa_corpora
    Rglossa::Corpus.drop_translation_table!
  end
end
