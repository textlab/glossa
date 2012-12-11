module Rglossa
  class CorpusText < ActiveRecord::Base
    has_and_belongs_to_many :metadata_values

    class << self

      # Returns all corpus texts that are associated with the metadata values
      # that have the given database ids
      def matching_metadata(metadata_value_ids)
        CorpusText
        .select('startpos, endpos').uniq
        .joins('INNER JOIN rglossa_corpus_texts_metadata_values j ON ' +
          'j.rglossa_corpus_text_id = rglossa_corpus_texts.id')
        .where(j: { rglossa_metadata_value_id: metadata_value_ids })
      end

    end

  end
end