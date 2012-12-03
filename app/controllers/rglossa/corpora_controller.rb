module Rglossa
  class CorporaController < ApplicationController

    def index
      corpora = Corpus.all

      respond_to do |format|
        format.json { render json: corpora }
        format.xml  { render xml:  corpora }
      end
    end


    def show
      corpus = Corpus.find(params[:id])

      respond_to do |format|
        format.json { render json: corpus }
        format.xml  { render xml:  corpus }
      end
    end

  end
end