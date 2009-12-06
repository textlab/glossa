require 'spec_helper'

describe MetadataCategory do
  before(:each) do
    @valid_attributes = {
            :name => "value for name",
            :fieldtype => "value for type",
            :selector => "value for selector"
    }
    @new_metadata_category = MetadataCategory.new
    @new_metadata_category.valid?
  end

  it "should create a new instance given valid attributes" do
    MetadataCategory.create!(@valid_attributes)
  end

  it "should belong to zero or more corpora" do
    @new_metadata_category.should respond_to(:corpora)
  end

  it "should require a name" do
    @new_metadata_category.errors.full_messages.should include("Name can't be blank")
  end

  it "should require a fieldtype" do
    @new_metadata_category.errors.full_messages.should include("Fieldtype can't be blank")
  end
end
