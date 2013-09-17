module Rglossa
  class MetadataValuesController < ApplicationController

    def index
      raise "Metadata category ID is missing!" unless received_id_for?(:metadata_category)

      metadata = []
      metadata_value_ids = params[:metadata_value_ids]

      if metadata_value_ids && metadata_value_ids.length > 0
        # Restrict the set of possible values for this metadata category based on the set of
        # values that has already been selected from other categories to prevent selection of
        # incompatible values. We do this by finding all corpus texts that are associated with
        # the already chosen values and then finding all values from the desired category that
        # are associated with the same set of texts.
        metadata = metadata_value_ids.map do |cat, vals|
          # Don't restrict the possible values based on previous choices within the *same* category,
          # because then we could only select a single value from each category...
          cat != params[:metadata_category_id] ? vals.map(&:to_i) : nil
        end
        metadata = metadata.compact.flatten
      end

      if metadata.empty?
        values =  MetadataValue.where(metadata_category_id: params[:metadata_category_id])
      else
        values =  MetadataValue.uniq.joins('INNER JOIN rglossa_corpus_texts_metadata_values j ' +
                                               'ON j.rglossa_metadata_value_id = rglossa_metadata_values.id ' +
                                               'INNER JOIN rglossa_corpus_texts t ' +
                                               'ON j.rglossa_corpus_text_id = t.id ' +
                                               'INNER JOIN rglossa_corpus_texts_metadata_values j2 ' +
                                               'ON j2.rglossa_corpus_text_id = t.id').where(
            metadata_category_id: params[:metadata_category_id],
            j2: {rglossa_metadata_value_id: metadata}
        )
      end

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