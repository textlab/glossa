module Rglossa
  module Speech
    module SearchEngines
      class SpeechCwbSearch < ::Rglossa::SearchEngines::CwbSearch

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

        def default_context_size
          7
        end

        def s_attr
          "sync_time"
        end

        def result_attrs
          "+sync_time +sync_end +who_name +who_line_key"
        end

        # Creates the data structure that is needed by jPlayer for a single search result
        def create_media_obj(overall_starttime, overall_endtime,
                             starttimes, endtimes, lines, speakers, line_key)
          word_attr = 'word' # TODO: make configurable?
          obj = {
            title: '',
            last_line: lines.size - 1,
            display_attribute: word_attr,
            corpus_id: corpus.id,
            mov: {
              supplied: 'm4v',
              path: corpus.media_path || "media/#{corpus.code}",
              line_key: line_key,
              start: overall_starttime,
              stop: overall_endtime
            },
            divs: {
              annotation: {
              }
            }
          }
          matching_line_index = nil
          lines.each_with_index do |line, index|
            token_no = -1
            is_match = false
            obj[:divs][:annotation][index] = {
              speaker: speakers.shift || '',
              line: line.split(/\s+/).reduce({}) do |acc, token|
                token_no += 1

                # Note: when matching a phrase, left and right braces will be on different
                # tokens!
                if token.match(/^{{(.*)/) || token.match(/(.*)}}$/)
                  is_match = true
                  matching_line_index = index
                  token.sub!(/^{{/, '')
                  token.sub!(/}}$/, '')
                end
                attr_values = token.split('/')
                display_attrs = corpus.display_attrs || []
                langs = corpus.languages || []
                acc[token_no] = Hash[[word_attr].concat(display_attrs).zip(attr_values)]
                if langs.map{|h|h[:lang]} == [:zh] && acc[token_no]["phon"]
                  acc[token_no]["phon"] = Ting.pretty_tones(acc[token_no]["phon"]) rescue
                  acc[token_no]["phon"]
                end
                acc
              end,
              from: starttimes.shift,
              to: endtimes.shift
            }
            obj[:divs][:annotation][index][:is_match] = is_match
          end
          obj[:start_at] = matching_line_index
          obj[:end_at]   = matching_line_index
          obj[:min_start] = 0
          obj[:max_end] = lines.size - 1
          obj
        end


        def transform_results(res)
          line_keys = Set.new

          transformed = res.map do |result|
            lines = []
            starttimes = []
            endtimes = []
            displayed_lines = []
            speakers = []
            overall_starttime = nil
            overall_endtime = nil
            line_key = nil

            # If the matching word/phrase is at the beginning of the segment, CQP puts the braces
            # marking the start of the match before the starting segment tag
            # (e.g. {{<turn_endtime 38.26><turn_starttime 30.34>went/go/PAST>...). Probably a
            # bug in CQP? In any case we have to fix it by moving the braces to the
            # start of the segment text instead. Similarly if the match is at the end of a segment.
            result.gsub!(/{{((?:<\S+?\s+?\S+?>\s*)+)/, '\1{{') # find start tags with attributes (i.e., not the match)
            result.gsub!(/((?:<\/\S+?>\s*)+)}}/, '}}\1')        # find end tags

            result.scan(/<sync_time\s+([\d\.]+)><sync_end\s+([\d\.]+)>(.*?)<\/sync_end><\/sync_time>/) do |m|
              starttime, endtime, line = m

              overall_starttime ||= starttime
              overall_endtime     = endtime

              line.scan(/<who_name\s+(.+?)>(.*?)<\/who_name>/) do |m2|
                speakers << m2[0]

                l = m2[1]
                l.sub!(/^<who_line_key\s+(\d+)>(.*)<\/who_line_key>/, '\2')
                # All line keys within the same result should point to the same media file,
                # so it doesn't matter if we assign this several times for the same result
                line_key = $1
                lines << l
                # Repeat the start and end time for each speaker within the same segment
                starttimes << starttime
                endtimes   << endtime
              end
              # Add the line key found for this result to the set of line keys for this result page
              line_keys << line_key if line_key

              # We asked for a context of several units to the left and right of the unit containing
              # the matching word or phrase, but only the unit with the match (marked by angle
              # brackets) should be included in the search result shown in the result table.
              if line =~ /{{.+}}/
                # Remove line key attribute tags, since they would only confuse the client code
                displayed_lines << line.gsub(/<\/?who_line_key.*?>/, '')
              end
            end

            displayed_lines_str = displayed_lines.join
            if line_key
              # Only add a media object to the data returned to the client if the corpus contains
              # line keys that we can use to determine which media file to show for each result
              media_obj = create_media_obj(overall_starttime, overall_endtime,
                                           starttimes, endtimes, lines, speakers, line_key)
              {
                text: displayed_lines_str,
                media_obj: media_obj,
                line_key: line_key
              }
            else
              {
                text: displayed_lines_str
              }
            end
          end

          # Now that all results in this page have been processed, we have a set of line keys
          # (one for each result). Find out how they map to media file names and put the name
          # as a property on the media object that is returned to the client.
=begin
          if line_keys.present?
            conn = ActiveRecord::Base.connection

            ActiveRecord::Base.transaction do
              conn.execute("CREATE TEMPORARY TABLE line_keys (line_key INTEGER)")
              conn.execute("INSERT INTO line_keys " + line_keys.map{|i| "SELECT %d" % i}.join(" UNION "))
              basenames = conn.execute("SELECT line_key, basename FROM line_keys LEFT JOIN rglossa_media_files
                                          ON line_key_begin <= line_key AND line_key <= line_key_end
                                          WHERE corpus_id = %d" % corpus.id).reduce({}) do |m, f|
                m[f[0]] = f[1]
                m
              end
              conn.execute("DROP TABLE line_keys")

              new_pages[page_no].map! do |result|
                result[:media_obj][:mov][:movie_loc] = URI.encode basenames[result[:line_key].to_i]
                result
              end
            end
          end
=end

          transformed
        end


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
          AND texts.corpus_id = #{corpus.id}
          AND tid.text_value IN (#{tid_list})
          SQL

          pairs.reduce({}) { |h, pair| h[pair[0]] = pair[1]; h }
        end

      end
    end
  end
end
