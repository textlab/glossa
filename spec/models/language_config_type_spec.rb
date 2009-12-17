require 'spec_helper'

describe LanguageConfigType do
  before(:each) do
    @valid_attributes = {
      :name => "Norwegian bokmål, written, Constraint Grammar",
      :tagger => :obt
    }
    @new_language_config_type = LanguageConfigType.new
    @new_language_config_type.valid?
  end

  it "should create a new instance given valid attributes" do
    LanguageConfigType.create!(@valid_attributes)
  end

  it "should have a name" do
    @new_language_config_type.errors.full_messages.should include("Name can't be blank")
  end

  it "may use a tagger" do
    @new_language_config_type.should respond_to(:tagger)
  end
end
