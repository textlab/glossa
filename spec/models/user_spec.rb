require 'spec_helper'

describe User do
  before(:each) do
    @valid_attributes = {
      :username => "test",
      :email => "test@test.no",
      :password => "test",
      :password_confirmation => "test"
    }
    @new_user = User.new
    @new_user.valid?
  end

  it "should create a new instance given valid attributes" do
    User.create!(@valid_attributes)
  end

  it "should have a preference collection" do
    @new_user.should respond_to(:preference_collection)
  end

  it "should destroy its preference collection when destroyed" do
    PreferenceCollection.delete_all
    u = User.create!(@valid_attributes)
    PreferenceCollection.count.should == 1
    u.destroy
    PreferenceCollection.count.should == 0
  end

  it "should have zero or more searches" do
    @new_user.should respond_to(:searches)
  end
end
