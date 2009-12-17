class User < ActiveRecord::Base
  acts_as_authentic
  has_one :preference_collection, :dependent => :destroy
  has_many :searches

  after_create :create_preference_collection
end
