module Rglossa
  class DeletedHit < ActiveRecord::Base
    self.table_name = "rglossa_delete_hits"
    belongs_to :search
  end
end
