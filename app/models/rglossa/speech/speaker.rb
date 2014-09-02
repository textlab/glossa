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
        def write_positions(filename, rows)
          # in Speaker, each row contains a string with a set of start and end
          # position that can be written directly to file
          rows.map! { |row| row.gsub(/\s+/, "\n").gsub(/-/, "\t") }
          File.write(filename, rows.join("\n"))
        end

      end

    end
  end
end
