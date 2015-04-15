class AddAdminToUsers < ActiveRecord::Migration
  def change
    add_column :rglossa_users, :admin, :boolean, :default => false
  end
end
