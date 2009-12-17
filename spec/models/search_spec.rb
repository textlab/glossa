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
            :queries => JSON.parse(queries),
            :search_options => JSON.parse(search_options),
            :metadata_selection => JSON.parse(metadata_selection)
    }
  end

  it "should create a new instance given valid attributes" do
    Search.create!(@valid_attributes)
  end
end
