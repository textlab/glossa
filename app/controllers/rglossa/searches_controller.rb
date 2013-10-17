require 'builder'

module Rglossa
  class SearchesController < ApplicationController
    respond_to :json, :xml

    def index
      @searches = current_user.searches
      respond_with(@searches)
    end

    def show
      @search = model_class.find(params[:id])

      respond_to do |format|
        format.any(:json, :xml) do
          render request.format.to_sym =>
            @search.to_json(
              root: true,
              only: [:id, :num_hits, :max_hits],
              methods: :first_two_result_pages)
        end
      end
    end

    def create
      @search = create_search(params[model_param])

      respond_to do |format|
        format.any(:json, :xml) do
          # With certain search engines, the number of hits is not determined
          # until we actually fetch a result page, so we do that explicitly
          # before creating the response
          pages = @search.first_two_result_pages
          root = @search.class.to_s.demodulize.underscore
          s = {}
          s[root] = {
              id: @search.id,
              num_hits: @search.num_hits,
              max_hits: @search.max_hits,
              first_two_result_pages: pages,
              current_corpus_part: @search.current_corpus_part
            }

          render request.format.to_sym => s.to_json
        end
      end
    end

    def results
      # FIXME: USE current_user!!
      # search = current_user.searches.find(model_param_id)
      search = model_class.find(params[:id])
      if search
        pages = search.get_result_pages(params[:pages])

        @results = {
          search_results: {
            search_id: search.id,
            pages: pages
          }
        }
      end
      respond_with(@results)
    end

    def count
      @search = model_class.find(params[:id])
      corpus = Corpus.find_by_short_name(@search.queries.first['corpusShortName'])
      parts = corpus.config[:parts]

      num_hits = parts ? @search.get_total_corpus_part_count(parts) : @search.num_hits

      respond_to do |format|
        format.any(:json, :xml) do
          render request.format.to_sym => num_hits
        end
      end
    end

    ########
    private
    ########

    # The name of the search model as it occurs in query parameters, e.g.
    # "cwb_search"
    def model_param
      # model_class is defined by derived controllers for the individual search
      # types we support
      model_class.to_s.demodulize.underscore
    end

    def model_param_id
      "#{model_param}_id"
    end

    def create_search(search_params)
      # Run inside a transaction so that no search record is created if
      # running queries throws an exception
      ActiveRecord::Base.transaction do
        search = model_class.new(search_params)
        search.user_id = (Rails.env == 'development' && !current_user) ? 1 : current_user.id
        search.save
        search
      end
    end
  end
end
