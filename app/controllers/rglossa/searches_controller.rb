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
      if params['format'] == 'fcskwic'
        p = {queries: [params]}
      else
        p = params[model_param]
      end

      # Run inside a transaction so that no search record is created if
      # running queries throws an exception
      ActiveRecord::Base.transaction do
        @search = model_class.new(p)
        @search.user_id = (Rails.env == 'development' && !current_user) ? 1 : current_user.id
        @search.save
      end

      respond_to do |format|
        format.any(:json, :xml) do
          render request.format.to_sym =>
            @search.to_json(
              root: true,
              only: [:id, :num_hits, :max_hits],
              methods: :first_two_result_pages)
        end

        format.fcskwic do |format|
          builder = Builder::XmlMarkup.new
          xml = builder.fsc(:DataView, type: 'application/x-clarin-fcs-kwic+xml') do |v|
            v.kwic(:kwic, 'xmlns:kwic' => 'http://clarin.eu/fcs/1.0/kwic') do |k|
              @search.get_result_page(1).each do |hit|
                s_unit = hit.sub(/^\s*\d+:\s*<s_id.+>:\s*/, '')  # remove position and s ID
                left, keyword, right = s_unit.match(/(.+)<(.+)>(.+)/)[1..-1].map { |s| s.strip }
                k.kwic(:c, type: 'left') { |l| l << left }
                k.kwic(:kw) { |k| k << keyword }
                k.kwic(:c, type: 'right') { |l| l << right }
              end
            end
          end
          render xml: xml
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
