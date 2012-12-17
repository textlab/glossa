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
              only: [:id, :num_hits],
              methods: :first_two_result_pages)
        end
      end
    end

    def create
      # Run inside a transaction so that no search record is created if
      # running queries throw an exception
      ActiveRecord::Base.transaction do
        @search = model_class.create(params[model_param])
      end

      respond_to do |format|
        format.any(:json, :xml) do
          render request.format.to_sym =>
            @search.to_json(
              root: true,
              only: [:id, :num_hits],
              methods: :first_two_result_pages)
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
  end
end