class DeletedHit < ActiveRecord::Base
  belongs_to :search
  validates_presence_of :search_id
end
