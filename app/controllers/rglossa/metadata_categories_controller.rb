module Rglossa
  class MetadataCategoriesController < ApplicationController
    def index
      raise "Corpus ID is missing!" unless received_id_for?(:corpus)

      categories = MetadataCategory.where(corpus_id: params[:corpus_id])

      respond_to do |format|
        format.json { render json: categories }
        format.xml  { render xml:  categories }
      end
    end
  end
end