module Rglossa
  module Speech
    class Speaker < ::Rglossa::CorpusText

      class << self

        ########
        private
        ########

        # Overrides the one in CorpusText
        def position_field_str
          'positions'
        end

        # Overrides the one in CorpusText
        def run_query(sql)
          connection.select_values(sql)
        end

        # Overrides the one in CorpusText
        def write_positions(filename, conditions, sql)
          sql << " WHERE #{conditions.join(" AND ")} AND positions IS NOT NULL"
          rows = run_query(sql)

          # in Speaker, each row contains a string with a set of dash-separated start and end
          # positions that need to be split and spaces replaced by newlines. Unlike with CorpusText
          # we cannot ask MySQL to write directly to outfile since we need to do this processing
          # first.
          rows.map! { |row| row.gsub(/\s+/, "\n").gsub(/-/, "\t") }
          File.write(filename, rows.join("\n"))
        end

      end

    end
  end
end
