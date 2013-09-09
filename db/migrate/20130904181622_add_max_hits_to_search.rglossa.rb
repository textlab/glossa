# This migration comes from rglossa (originally 20130730095239)
class AddMaxHitsToSearch < ActiveRecord::Migration
  def change
    add_column :rglossa_searches, :max_hits, :integer
  end
end
