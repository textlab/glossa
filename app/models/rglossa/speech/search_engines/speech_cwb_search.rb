module Rglossa
  module Speech
    module SearchEngines
      class SpeechCwbSearch < ::Rglossa::SearchEngines::CwbSearch

        def default_context_size
          7
        end

        def geo_distr
          named_query = query_info[:named_query]
          commands = [
              "set PrettyPrint off",
              %Q{set DataDirectory "#{Dir.tmpdir}"},
              "group #{named_query} match who_name by match phon"]

          table = run_cqp_commands(commands).split("\n").map { |line| line.split("\t") }
          speaker_tids = table.map { |row| row[1] }

          tids_to_places = find_tids_to_places(speaker_tids)

          place_totals = Hash.new { |hash, key| hash[key] = 0 }
          phons_per_place = Hash.new { |hash, key| hash[key] = Hash.new { |hash2, key2| hash2[key2] = 0 } }
          table.each do |row|
            phon, tid, freq = row
            place = tids_to_places[tid]

            if place.present?
              place_totals[place] += freq.to_i
              phons_per_place[phon][place] += freq.to_i
            end
          end

          {
              place_totals: place_totals,
              phons_per_place: phons_per_place
          }
        end

        ########
        private
        ########

        # Takes a list of text IDs ("tid"s), which for speech corpora are actually speaker
        # IDs, and finds, for each tid, the place name that is associated with the same
        # corpus text as the tid in the corpus that the current search belongs to.
        #
        # Returns a hash with tids as keys and place names as values. Note that several tids
        # may map to the same place name.
        def find_tids_to_places(tids)
          tid_list = tids.map { |tid| "'#{tid}'" }.join(',')

          pairs = connection.select_rows <<-SQL
          SELECT DISTINCT tid.text_value, place.text_value
          FROM rglossa_metadata_categories t_cat, rglossa_metadata_categories p_cat,
                  rglossa_metadata_values tid, rglossa_metadata_values place,
                  rglossa_corpus_texts_metadata_values j1, rglossa_corpus_texts_metadata_values j2,
                  rglossa_corpus_texts texts
          WHERE t_cat.short_name = 'tid' AND p_cat.short_name = 'place'
          AND tid.metadata_category_id = t_cat.id AND place.metadata_category_id = p_cat.id
          AND tid.id   = j1.rglossa_metadata_value_id AND texts.id = j1.rglossa_corpus_text_id
          AND place.id = j2.rglossa_metadata_value_id AND texts.id = j2.rglossa_corpus_text_id
          AND texts.corpus_id = #{query_info[:corpus].id}
          AND tid.text_value IN (#{tid_list})
          SQL

          pairs.reduce({}) { |h, pair| h[pair[0]] = pair[1]; h }
        end

      end
    end
  end
end
