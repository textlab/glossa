module Rglossa
  class CorporaController < ApplicationController
    respond_to :json, :xml

    def index
      @corpora = Corpus.all
      respond_with @corpora
    end


    def show
      @corpus = Corpus
        .includes(metadata_categories: [:translations, :metadata_values])
        .find(params[:id])

      respond_with @corpus
    end

  end
end