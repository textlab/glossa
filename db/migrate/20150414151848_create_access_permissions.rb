class CreateAccessPermissions < ActiveRecord::Migration
  def change
    create_table :rglossa_access_permissions do |t|
      t.belongs_to :user, index: true, null: false
      t.belongs_to :corpus, index: true, null: false
    end
  end
end
