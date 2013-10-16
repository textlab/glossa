# This migration comes from rglossa (originally 20131014225856)
class SetNumHitsToZero < ActiveRecord::Migration
  def up
    change_column :rglossa_searches, :num_hits, :integer, null: false, default: 0
  end

  def down
    change_column :rglossa_searches, :num_hits, :integer
  end
end
