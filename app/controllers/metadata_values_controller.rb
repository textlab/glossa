class MetadataValuesController < ApplicationController

  def index
    raise "Corpus ID is missing!" unless received_id_for?(:corpus)

    values =  MetadataValue
      .joins(:metadata_category)
      .where(metadata_categories: {corpus_id: params[:corpus_id]})

    respond_to do |format|
      format.json { render json: values }
      format.xml  { render xml:  values }
    end
  end

end
