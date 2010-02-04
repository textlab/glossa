require 'spec_helper'

describe UserGroup do
  before(:each) do
    @valid_attributes = {
      :name => 'MyCorpusGroup'
    }
    @new_user_group = UserGroup.new
    @new_user_group.valid?
  end

  it "should create a new instance given valid attributes" do
    UserGroup.create!(@valid_attributes)
  end

  it "may contain users" do
    @new_user_group.should respond_to(:users)
  end
end
