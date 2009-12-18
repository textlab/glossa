require 'spec_helper'

describe Segment do
  before(:each) do
    @valid_attributes = {
      :corpus_text_id => 1,
      :s_id => "value for s_id",
      :contents => "value for contents"
    }
    @new_segment = Segment.new
    @new_segment.valid?
  end

  it "should create a new instance given valid attributes" do
    Segment.create!(@valid_attributes)
  end

  it "should belong to a corpus text" do
    @new_segment.errors.full_messages.should include("Corpus text can't be blank")
  end
end
