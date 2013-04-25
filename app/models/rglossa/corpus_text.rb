module Rglossa
  class CorpusText < ActiveRecord::Base
    belongs_to :corpus
    has_and_belongs_to_many :metadata_values, join_table: 'rglossa_corpus_texts_metadata_values',
                            foreign_key: 'rglossa_corpus_text_id',
                            association_foreign_key: 'rglossa_metadata_value_id'

    class << self

      def by_tid(tid)
        joins('INNER JOIN rglossa_corpus_texts_metadata_values j ON ' +
                   'j.rglossa_corpus_text_id = rglossa_corpus_texts.id')
        .joins('INNER JOIN rglossa_metadata_values v ON j.rglossa_metadata_value_id = v.id')
        .joins('INNER JOIN rglossa_metadata_categories c ON v.metadata_category_id = c.id')
        .where(c: {short_name: 'tid'}, v: { text_value: tid })
      end

      # Returns start and stop positions of all corpus texts that are associated with the metadata
      # values that have the given database ids
      # TODO: This is MySQL-specific syntax - implement for other databases as well
      def print_positions_matching_metadata(metadata_value_ids, positions_filename)
        conditions = sanitize_sql(["j.rglossa_metadata_value_id IN (?)", metadata_value_ids])
        connection.execute("SELECT DISTINCT startpos, endpos FROM rglossa_corpus_texts " +
                               "INNER JOIN rglossa_corpus_texts_metadata_values j " +
                               "ON j.rglossa_corpus_text_id = rglossa_corpus_texts.id " +
                               "WHERE #{conditions} INTO OUTFILE '#{positions_filename}'")
      end

    end

  end
end