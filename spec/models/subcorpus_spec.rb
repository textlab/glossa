require 'spec_helper'

describe Subcorpus do
  before(:each) do
    @valid_attributes = {
      :corpus_id => 1,
      :name => "value for name"
    }
    @new_subcorpus = Subcorpus.new
    @new_subcorpus.valid?
  end

  it "should create a new instance given valid attributes" do
    Subcorpus.create!(@valid_attributes)
  end

  it "should belong to a corpus" do
    @new_subcorpus.errors.full_messages.should include("Corpus can't be blank")
  end

  it "should have and belong to many corpus texts" do
    @new_subcorpus.should respond_to(:corpus_texts)
  end
end
