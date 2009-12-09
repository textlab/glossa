require 'spec_helper'

query = [{
        :language_config => 2,
        :form => 'man',
        :options => {:word => ['lemma form', 'case sensitive'], :pos => 'noun'}
}, {
        :language_config => 1,
        :form => 'mann',
        :options => {:number => 'pl'}
}]

describe Search do
  before(:each) do
    @valid_attributes = {
            :query => query,
            :is_regexp => false,
            :search_within => "value for search_within",
            :page_size => 1,
            :randomize => false,
            :skip_total => false,
            :context_type => "value for context_type",
            :left_context => 1,
            :right_context => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Search.create!(@valid_attributes)
  end
end
