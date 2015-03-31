module Rglossa
  class MetadataValue < ActiveRecord::Base
    self.table_name = "rglossa_metadata_values"
    belongs_to :metadata_category
    has_and_belongs_to_many :corpus_texts, join_table: 'rglossa_corpus_texts_metadata_values',
                            foreign_key: 'rglossa_metadata_value_id',
                            association_foreign_key: 'rglossa_corpus_text_id'

    validates_presence_of :metadata_category_id

    def as_json(options={})
      opts = {only: :id, methods: :text}.merge(options)
      super(opts)
    end

    class << self

      def get_constrained_list(category_id, constraining_values)
        ids = connection.execute(
          sanitize_sql(['SELECT DISTINCT rglossa_metadata_values.id ' +
          'FROM rglossa_metadata_values INNER JOIN rglossa_corpus_texts_metadata_values j ' +
          'ON j.rglossa_metadata_value_id = rglossa_metadata_values.id ' +
          'INNER JOIN rglossa_corpus_texts t ' +
          'ON j.rglossa_corpus_text_id = t.id ' +
          'INNER JOIN rglossa_corpus_texts_metadata_values j2 ' +
          'ON j2.rglossa_corpus_text_id = t.id ' +
          'WHERE metadata_category_id = %s AND j2.rglossa_metadata_value_id IN (%s)',
          category_id, *constraining_values])).to_a
        find(ids)
      end

      def with_type_and_value(value_type, value)
        column = "#{value_type.demodulize.underscore}_value"
        value = value_type.constantize.convert_text_value(value)
        where(["#{column} = ?", value]).first
      end
    end
  end
end
