require 'spec_helper'

describe PreferenceCollection do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :page_size => 1,
      :skip_total => 1,
      :context_type => "value for context_type",
      :left_context => 1,
      :right_context => 1
    }
    @new_preference_collection = PreferenceCollection.new
    @new_preference_collection.valid?
  end

  it "should create a new instance given valid attributes" do
    PreferenceCollection.create!(@valid_attributes)
  end

  it "should belong to a user" do
    @new_preference_collection.errors.full_messages.should include("User can't be blank")
  end
end
