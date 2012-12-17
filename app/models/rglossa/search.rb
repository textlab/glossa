module Rglossa
  class Search < ActiveRecord::Base
    belongs_to :user
    has_many :deleted_hits, dependent: :destroy

    serialize :queries, Array
    serialize :search_options, Hash
    serialize :metadata_value_ids, Hash

    after_create :run_queries

    # This is run automatically after the seach record has been created. It
    # should set num_hits on the model and store either the actual search
    # results or the search itself in some way that makes it possible to
    # retrieve results using get_result_page (which also needs to be
    # implemented by each subclass).
    def run_queries
      raise "Implement this method in subclasses and throw an " +
        "Rglossa::QueryError if running queries produces an error."
    end

    # This will be included in the response returned from the *create* action
    # so that we don't have to send an extra request in order to get the first
    # two result pages after creating the search (we get two pages in order to
    # preload the second page when the user views the first page)
    def first_two_result_pages
      get_result_pages([1, 2])
    end

    # Returns a hash with page numbers as keys and page results as values
    def get_result_pages(page_nos)
      pages = {}
      page_nos.map(&:to_i).each do |page_no|
        pages[page_no] = get_result_page(page_no)
      end
      pages
    end

    def get_result_page(page_no)
      raise "Implement in subclasses"
    end

    ########
    private
    ########

    def page_size
      # TODO: Get this from the user's preferences or something
      20
    end

  end
end