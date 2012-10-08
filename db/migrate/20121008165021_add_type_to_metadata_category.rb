class AddTypeToMetadataCategory < ActiveRecord::Migration
  def change
    add_column :metadata_categories, :type, :string
  end
end
