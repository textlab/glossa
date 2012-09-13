class User < ActiveRecord::Base
  has_many :searches
end
