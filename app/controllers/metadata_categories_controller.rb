class MetadataCategoriesController < ApplicationController
  def index
    categories = MetadataCategory.where{corpus_id == params[:corpus_id]}
  end
end
