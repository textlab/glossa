module Rglossa
  class Search < ActiveRecord::Base
    attr_accessible :queries, :metadata_value_ids, :num_hits, :max_hits, :current_corpus_part

    # Non-persisted attribute that is only used for keeping track of the
    # corpus part currently being searched (only relevant for multi-part corpora)
    attr_accessor :current_corpus_part

    belongs_to :user
    has_many :deleted_hits, dependent: :destroy

    serialize :queries, Array
    serialize :search_options, Hash
    serialize :metadata_value_ids, Hash
    serialize :corpus_part_counts, Array

    after_initialize -> {
      self.current_corpus_part = 0
      self.corpus_part_counts = []
    }
    after_create :run_queries

    # This is run automatically after the search record has been created. It
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
      15
    end

  end
end