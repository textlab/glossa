require 'spec_helper'

describe DeletedHit do
  before(:each) do
    @valid_attributes = {
      :search_id => 1
    }
  end

  it "should create a new instance given valid attributes" do
    DeletedHit.create!(@valid_attributes)
  end

  it "should belong to a search" do
    @valid_attributes[:search_id] = nil
    DeletedHit.new(@valid_attributes).should_not be_valid
  end
end
