module Rglossa
  class MetadataValuesController < ApplicationController

    def index
      raise "Metadata category ID is missing!" unless received_id_for?(:metadata_category)

      values =  MetadataValue.where(metadata_category_id: params[:metadata_category_id])

      unless values.empty? || params[:query].blank?
        value_class = values.first.type.constantize

        # Different subclasses of MetadataValue implement different SQL searches
        values = value_class.search(params[:query], values)
      end

      respond_to do |format|
        format.json { render json: { metadata_values: values } }
        format.xml  { render xml:  values }
      end
    end

  end
end