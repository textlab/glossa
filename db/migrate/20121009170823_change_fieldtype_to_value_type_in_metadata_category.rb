class ChangeFieldtypeToValueTypeInMetadataCategory < ActiveRecord::Migration
  def change
    rename_column :metadata_categories, :fieldtype, :value_type
  end
end
