module Rglossa
  class Search < ActiveRecord::Base
    belongs_to :user
    has_many :deleted_hits, dependent: :destroy

    serialize :queries, Array
    serialize :search_options, Hash
    serialize :metadata_selection, Hash

    # This will be included in the response returned from the *create* action so
    # that we don't have to send an extra request in order to get the first
    # result page after creating the search.
    def first_result_page
      get_result_page(0)
    end

    def get_result_page(page_no)
      {some: 'test', data: 'here'}
    end
  end
end