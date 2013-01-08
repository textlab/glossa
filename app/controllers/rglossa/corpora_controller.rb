module Rglossa
  class CorporaController < ApplicationController
    respond_to :json, :xml

    def index
      @corpora = Corpus.scoped
      set_query_params

      respond_with @corpora
    end


    def show
      @corpus = Corpus
        .includes(metadata_categories: [:translations, :metadata_values])
        .find(params[:id])

      respond_with @corpus
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

  end
end