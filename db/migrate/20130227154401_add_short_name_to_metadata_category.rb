class AddShortNameToMetadataCategory < ActiveRecord::Migration
  def change
    add_column :rglossa_metadata_categories, :short_name, :string
  end
end
