require 'spec_helper'

describe Search do
  before(:each) do
    @valid_attributes = {
            :owner_id => 1,
            :queries => JSON.parse(SAMPLE_SEARCH_DATA[:queries]),
            :search_options => JSON.parse(SAMPLE_SEARCH_DATA[:search_options]),
            :metadata_selection => JSON.parse(SAMPLE_SEARCH_DATA[:metadata_selection])
    }
    @new_search = Search.new
    @new_search.valid?
  end

  it "should create a new instance given valid attributes" do
    Search.create!(@valid_attributes)
  end

  it "should belong to a user" do
    @new_search.errors.full_messages.should include("Owner can't be blank")
  end
end
