require 'spec_helper'

queries = <<END
[{"language_config_id": 2, "form": "man", "options": {"word": ["lemma form", "case sensitive"], "pos": "noun"}}, \
{"language_config_id": 1, "form": "mann", "options": {"number": "pl"}}]
END

search_options = <<END
{"is_regexp": false, "search_within": "s", "page_size": 20, "max_results": 2000, \
"randomize": false, "skip_total": false, "context_type": "word", "left_context": 7, "right_context": 7}
END

metadata_selection = <<END
{"publisher": "Kunnskapsforlaget", "category": "AV0%"}
END

describe Search do
  before(:each) do
    @valid_attributes = {
            :user_id => 1,
            :queries => JSON.parse(queries),
            :search_options => JSON.parse(search_options),
            :metadata_selection => JSON.parse(metadata_selection)
    }
    @new_search = Search.new
    @new_search.valid?
  end

  it "should create a new instance given valid attributes" do
    Search.create!(@valid_attributes)
  end

  it "should belong to a user" do
    @new_search.errors.full_messages.should include("User can't be blank")
  end
end
