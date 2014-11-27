class AddCimdiToCorpora < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :cimdi, :text
  end
end
