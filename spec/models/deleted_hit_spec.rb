require 'spec_helper'

describe DeletedHit do
  before(:each) do
    @valid_attributes = {
      :search_id => 1
    }
    @new_deleted_hit = DeletedHit.new
    @new_deleted_hit.valid?
  end

  it "should create a new instance given valid attributes" do
    DeletedHit.create!(@valid_attributes)
  end

  it "should belong to a search" do
    @new_deleted_hit.errors.full_messages.should include("Search can't be blank")
  end
end
