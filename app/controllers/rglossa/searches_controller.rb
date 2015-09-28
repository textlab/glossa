require 'builder'
require './lib/orientdb'

module Rglossa
  class SearchesController < ApplicationController
    include OrientDb

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
              only: [:id, :num_hits])
        end
      end
    end

    def create
      # Search is performed in three steps. In the first step, we create a new
      # search object in the database and search for a single page of search
      # results (as defined by the cut parameter sent by the client) so as to
      # be able to display some results very quickly. In the second step, we
      # retrieve the previously saved search object from the database and
      # search for a larger number of search result pages (e.g. 20, but again
      # defined by the cut parameter). In the final step, we do the same, but
      # this time the cut parameter will be nil, causing the search to be
      # unrestricted.
      if params[:step] == 1
        @search = create_search(params[model_param].except(:sortBy))
      else
        @search = one(model_class, 'SELECT FROM #TARGET', {target: params[:search_id]})
      end
      @search.run_queries(params[:cut])

      respond_to do |format|
        format.any(:json, :xml) do
          if params[:step] == 1
            # With certain search engines, the number of hits is not determined
            # until we actually fetch a result page, so we do that explicitly
            # before creating the response
            res = @search.get_results(params[:start], params[:end], sort_by: params[:sortBy])

            render request.format.to_sym => { search: @search, result: res }
          else
            render request.format.to_sym => { search: @search }
          end
        end
      end
    end

    def results
      # FIXME: USE current_user!!
      # search = current_user.searches.find(model_param_id)
      search = model_class.find(params[:id])

      if search
        search.current_corpus_part = params[:current_corpus_part].to_i
        pages = transform_result_pages(search.get_result_pages(params[:pages],
                                                               sort_by: params[:sortBy]))

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
      corpus = get_corpus_from_query
      parts = corpus.config[:parts]

      num_hits = parts ? @search.get_total_corpus_part_count(parts) : @search.count

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
      corpus = one(Corpus, 'SELECT @rid, code, search_engine, encoding FROM #TARGET',
                   {target: search_params[:corpus_id]})

      search = create_model(model_class,
                            'CREATE VERTEX Search SET queries = ?, metadata_value_ids = ?',
                            [JSON.dump(search_params[:queries]),
                             search_params[:metadata_value_ids] || []])
      run_sql("CREATE EDGE InCorpus FROM #{search.rid} TO #{corpus.rid}")
      search
    end

    def get_corpus_from_query(search = nil)
      search ||= @search || model_class.find(params[:id])
      Corpus.find_by_short_name(search.corpus_short_name.downcase)
    end

    def transform_result_pages(pages)
      new_pages = {}
      pages.each do |page_no, page|
        new_pages[page_no] = page.map { |result|  {text: result} }
      end
      new_pages
    end

  end
end
