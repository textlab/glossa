require 'spec_helper'

describe Corpus do
  before(:each) do
    @valid_attributes = {
      :name => "value for name"
    }
    @new_corpus = Corpus.new
    @new_corpus.valid?
  end

  it "should create a new instance given valid attributes" do
    Corpus.create!(@valid_attributes)
  end

  it "should require a name" do
    @new_corpus.errors.full_messages.should include("Name can't be blank")
  end
end
