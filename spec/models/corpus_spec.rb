require 'spec_helper'

describe Corpus do
  before(:each) do
    @valid_attributes = {
      :name => "The Oslo Corpus of Tagged Norwegian Texts"
    }
    @new_corpus = Corpus.new
    @new_corpus.valid?
  end

  it "should create a new instance given valid attributes" do
    c = Corpus.create!(@valid_attributes)
  end

  it "should require a name" do
    @new_corpus.errors.full_messages.should include("Name can't be blank")
  end

  # Actually, we would like to require that a corpus has ONE or more language configs,
  # but unfortunately we have to create a corpus without language configs first, since
  # langauge configs are saved when the corpus is saved and the language configs validate
  # that they have a corpus_id, which they won't have until the corpus has been saved...
  it "should have zero or more language configs" do
    @new_corpus.should respond_to(:language_configs)
  end

  it "has and belongs to many metadata categories" do
    @new_corpus.should respond_to(:metadata_categories)
  end
end
