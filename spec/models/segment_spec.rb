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

  it "should have some contents" do
    @new_segment.errors.full_messages.should include("Contents can't be blank")
  end

  it "may have aligned segments" do
    s1 = Segment.new(:contents => 'AAA')
    s1.corpus_text_id = 1
    s1.save!

    s2 = Segment.new(:contents => 'BBB')
    s2.corpus_text_id = 1

    s3 = Segment.new(:contents => 'CCC')
    s3.corpus_text_id = 1

    s1.aligned_segments << s2
    s1.aligned_segments << s3
    s1.aligned_segments.size.should == 2
  end
end
