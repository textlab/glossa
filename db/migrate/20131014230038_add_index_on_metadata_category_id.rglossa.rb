# This migration comes from rglossa (originally 20130910221355)
class AddIndexOnMetadataCategoryId < ActiveRecord::Migration
  def change
    add_index :rglossa_metadata_values, :metadata_category_id
  end
end
