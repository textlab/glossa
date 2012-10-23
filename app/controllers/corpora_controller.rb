class CorporaController < ApplicationController

  def index
    @corpora = Corpus.all

    respond_to do |format|
      format.json { render json: @corpora }
    end
  end


  def show
    @corpus = Corpus.find(params[:id])

    respond_to do |format|
      format.json { render json: @corpus }
    end
  end

end
