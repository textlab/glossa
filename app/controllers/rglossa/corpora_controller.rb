module Rglossa
  class CorporaController < ApplicationController
    respond_to :json, :xml

    def index
      @corpora = Corpus.scoped
      set_query_params

      respond_with @corpora
    end


    def show
      @corpus = @corpus.find(params[:id])
      create_response
    end


    def find_by
      raise "No short_name provided" unless params[:short_name]
      @corpus = Corpus.where(short_name: params[:short_name]).first
      create_response
    end


    def cimdi
      @corpus = Corpus.where(short_name: params[:id]).first
      # TODO: Move the language list to a more suitable location
      @langs = {dan: 'Danish', fao: 'Faroese', isl: 'Icelandic',
                nor: 'Norwegian', swe: 'Swedish'}

      if @corpus.cimdi.empty?
        render xml: "No CIMDI metadata found for corpus #{params[:id]}", status: :unprocessable_entity
      end
    end


    ########
    private
    ########

    def set_query_params
      query = params[:query]
      if query
        query.each_pair do |key, value|
          @corpora = @corpora.where(key.underscore.to_sym => value)
        end
      end
    end

    def create_response
      respond_to do |format|
        format.json do
          @metadata_categories = @corpus.metadata_categories.includes(:translations)

          render json: {
              corpus: @corpus.as_json(
                  only: [:id, :name, :logo, :short_name, :search_engine],
                  methods: [:langs, :display_attrs, :extra_row_attrs,
                            :parts, :has_sound, :has_video, :has_phonetic, :has_map,
                            :metadata_categories]
              )
          }
        end

        format.xml { render @corpus }  # don't include metadata in XML
      end
    end

  end
end
