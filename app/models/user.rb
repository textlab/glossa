class User < ActiveRecord::Base
  acts_as_authentic
  has_one :preference_collection, :dependent => :destroy

  after_create :create_preference_collection
end
