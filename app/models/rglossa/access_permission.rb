class Rglossa::AccessPermission < ActiveRecord::Base
  self.table_name = "rglossa_access_permissions"
  belongs_to :user
  belongs_to :corpus
end
