class MetadataValuesController < ApplicationController

  def index
    raise "Corpus ID is missing!" unless received_id_for?(:corpus)

    render json: MetadataValue
      .joins(:metadata_category)
      .where('metadata_categories.corpus_id = ?', params[:corpus_id])
  end

end
