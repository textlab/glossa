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

      # Returns start and stop positions of all corpus texts that are associated with the
      # metadata values that have the given database ids, with an OR relationship between values
      # within the same category and an AND relationship between categories.
      # TODO: This is MySQL-specific syntax - implement for other databases as well
      def print_positions_matching_metadata(metadata, positions_filename)
        cat_sqls = ["SELECT DISTINCT #{position_field_str} FROM rglossa_corpus_texts t"]
        i = 0
        conditions = []

        metadata.each do |category_id, value_ids|
          i += 1

          if i == 1
            cat_sqls << "rglossa_corpus_texts_metadata_values j1 " +
                "ON j1.rglossa_corpus_text_id = t.id " +
                "INNER JOIN rglossa_metadata_values v1 " +
                "ON j1.rglossa_metadata_value_id = v1.id"
          else
            cat_sqls << "rglossa_corpus_texts_metadata_values j#{i} " +
                "ON j#{i}.rglossa_corpus_text_id = j#{i - 1}.rglossa_corpus_text_id " +
                "INNER JOIN rglossa_metadata_values v#{i} " +
                "ON j#{i}.rglossa_metadata_value_id = v#{i}.id "
          end
          conditions << sanitize_sql(["v#{i}.id IN (?) AND v#{i}.metadata_category_id = ?",
                                      value_ids.map(&:to_i), category_id.to_i])
        end

        sql = cat_sqls.join(' INNER JOIN ')
        write_positions(positions_filename, conditions, sql)
      end

      ########
      private
      ########

      # Overridden by Speaker
      def position_field_str
        'startpos, endpos'
      end

      # Overridden by Speaker
      def run_query(sql)
        connection.select_rows(sql)
      end

      # Overridden by Speaker
      def write_positions(filename, conditions, sql)
        if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite3'
          # for SQLite
          sql << " WHERE #{conditions.join(" AND ")}"
          rows = run_query(sql)

          # in CorpusText, each row contains a pair of start and end positions that
          # need to be joined by tab before being written to file
          File.write(filename, rows.map {|r| r.join("\t")}.join("\n"))
        else
          # for MySQL
          sql << " WHERE #{conditions.join(" AND ")} INTO OUTFILE '#{filename}'"
          connection.execute(sql)
        end
      end

    end

  end
end