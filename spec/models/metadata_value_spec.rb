require 'spec_helper'

describe MetadataValue do
  before(:each) do
    @valid_attributes = {
      :metadata_category_id => 1,
      :corpus_text_id => 1,
      :type => "value for type",
      :text_value => "value for text_value",
      :integer_value => 1,
      :date_value => Date.today,
      :boolean_value => false
    }
    @new_metadata_value = MetadataValue.new
    @new_metadata_value.valid?
  end

  it "should create a new instance given valid attributes" do
    MetadataValue.create!(@valid_attributes)
  end

  it "should belong to a metadata category" do
    @new_metadata_value.errors.full_messages.should include("Metadata category can't be blank")
  end

  it "should belong to a corpus text" do
    @new_metadata_value.errors.full_messages.should include("Corpus text can't be blank")
  end
end
