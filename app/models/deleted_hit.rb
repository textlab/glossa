class DeletedHit < ActiveRecord::Base
  has_paper_trail

  belongs_to :search
  validates_presence_of :search_id
end
