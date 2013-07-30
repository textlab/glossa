class AddMaxHitsToSearch < ActiveRecord::Migration
  def change
    add_column :rglossa_searches, :max_hits, :integer
  end
end
