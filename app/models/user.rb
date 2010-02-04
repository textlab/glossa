class User < ActiveRecord::Base
  acts_as_authentic
  has_and_belongs_to_many :user_groups
  has_one :preference_collection, :dependent => :destroy
  has_many :searches

  after_create :create_preference_collection
end
