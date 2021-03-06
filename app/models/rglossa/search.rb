require 'ostruct'
require './lib/orientdb'

module Rglossa
  class Search < OpenStruct
    include OrientDb

    def corpus
      @corpus ||= one(Corpus, "SELECT expand(out('inCorpus')) FROM #TARGET", {target: rid})
    end

    def query_array
      @query_array ||= JSON.parse(queries)
    end

    # This is run after the search record has been created. It
    # should set num_hits on the model and store either the actual search
    # results or the search itself in some way that makes it possible to
    # retrieve results using get_result_page (which also needs to be
    # implemented by each subclass).
    def run_queries(step, cut = nil, options = {})
      raise "Implement this method in subclasses and throw an " +
        "Rglossa::QueryError if running queries produces an error."
    end

    # This will be included in the response returned from the *create* action
    # so that we don't have to send an extra request in order to get the first
    # two result pages after creating the search (we get two pages in order to
    # preload the second page when the user views the first page)
    def first_two_result_pages(options = {})
      get_result_pages([1, 2], options)
    end

    # Returns a hash with page numbers as keys and page results as values
    def get_result_pages(page_nos, options = {})
      pages = {}
      page_nos.map(&:to_i).each do |page_no|
        pages[page_no] = get_result_page(page_no, options)
      end
      pages
    end

    def get_results(start, stop, options = {})
      raise "Implement in subclasses"
    end

    def count
      raise "Implement in subclasses"
    end

    def get_total_corpus_part_count(parts)
      query = queries.first['query'].gsub('"', '')
      self.num_hits = 0

      parts.each_with_index do |part, index|
        self.num_hits += corpus_part_counts[index] ||= get_corpus_part_count(part, query)
      end
      save!  # In case we made any new corpus part counts

      num_hits
    end

    def page_size
      # TODO: Get this from the user's preferences or something
      15
    end

    def get_corpus_part_count(part, query)
      raise "Implement this method in a subclass if you use multipart corpora"
    end

  end
end
