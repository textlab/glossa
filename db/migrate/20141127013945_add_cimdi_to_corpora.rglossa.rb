# This migration comes from rglossa (originally 20141127012945)
class AddCimdiToCorpora < ActiveRecord::Migration
  def change
    add_column :rglossa_corpora, :cimdi, :text
  end
end
