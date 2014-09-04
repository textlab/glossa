module Rglossa
  module Speech
    module SearchEngines
      class SpeechCwbSearchesController < Rglossa::SearchEngines::CwbSearchesController

        # Used by the base controller to find the right kind of model to work with
        def model_class
          SpeechCwbSearch
        end

        ########
        private
        ########

        def transform_result_pages(pages)
          corpus = get_corpus_from_query

          if corpus.extra_cwb_attrs
            starttime_attr = corpus.extra_cwb_attrs.detect { |a| a.match(/_(?:start)?time$/) }.sub(/^\+/, '')
            endtime_attr   = corpus.extra_cwb_attrs.detect { |a| a.match(/_end(?:time)?$/)   }.sub(/^\+/, '')
            speaker_attr   = corpus.extra_cwb_attrs.detect { |a| a.ends_with?('_name')   }.sub(/^\+/, '')
          end
          starttime_attr = 'turn_starttime' unless starttime_attr
          endtime_attr   = 'turn_endtime'   unless endtime_attr
          speaker_attr   = 'who_name'       unless speaker_attr

          new_pages = {}
          pages.each do |page_no, page|
            new_pages[page_no] = page.map do |result|
              puts result
              lines = []
              starttimes = []
              endtimes = []
              displayed_lines = []
              speakers = []
              overall_starttime = nil
              overall_endtime = nil

              # If the matching word/phrase is at the beginning of the segment, CQP puts the braces
              # marking the start of the match before the starting segment tag
              # (e.g. {{<turn_endtime 38.26><turn_starttime 30.34>went/go/PAST>...). Probably a
              # bug in CQP? In any case we have to fix it by moving the braces to the
              # start of the segment text instead. Similarly if the match is at the end of a segment.
              result.gsub!(/{{((?:<\S+?\s+?\S+?>\s*)+)/, '\1{{') # find start tags with attributes (i.e., not the match)
              result.gsub!(/((?:<\/\S+?>\s*)+)}}/, '}}\1')        # find end tags

              result.scan(/<#{starttime_attr}\s+([\d\.]+)><#{endtime_attr}\s+([\d\.]+)>(.*?)<\/#{endtime_attr}><\/#{starttime_attr}>/) do |m|
                endtime, starttime, line = m

                overall_starttime ||= starttime
                overall_endtime     = endtime

                starttimes << starttime
                endtimes   << endtime

                line.scan(/<#{speaker_attr}\s+(.+?)>(.*?)<\/#{speaker_attr}>/) do |m2|
                  speakers << m2[0]
                  lines << m2[1]
                end

                # We asked for a context of several units to the left and right of the unit containing
                # the matching word or phrase, but only the unit with the match (marked by angle
                # brackets) should be included in the search result shown in the result table.
                if line =~ /{{.+}}/
                  displayed_lines << line
                end
              end

              media_obj = create_media_obj(overall_starttime, overall_endtime,
                                           starttimes, endtimes, lines, speakers,
                                           corpus.display_attrs)

              # The client code expects a colon at the beginning of each result line, so put it in
              {
                  text: displayed_lines.join,
                  media_obj: media_obj
              }
            end
          end
          new_pages
        end

        # Creates the data structure that is needed by jPlayer for a single search result
        def create_media_obj(overall_starttime, overall_endtime,
            starttimes, endtimes, lines, speakers, display_attrs)
          word_attr = 'word' # TODO: make configurable?
          obj = {
              title: '',
              last_line: lines.size - 1,
              display_attribute: word_attr,
              mov: {
                  supplied: 'm4v',
                  path: '',
                  movie_loc: 'The_Story_of_Four_Oxen-Siyoum Abraha.mp3',
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
                  acc[token_no] = Hash[[word_attr].concat(display_attrs).zip(attr_values)]
                  acc
                end,
                from: starttimes.shift,
                to: endtimes.shift
            }
            obj[:divs][:annotation][index][:is_match] = is_match
          end
          start_at = matching_line_index - 1
          start_at = 0 if start_at < 0
          end_at   = matching_line_index + 1
          end_at   = lines.size - 1 if end_at >= lines.size
          obj[:start_at] = start_at
          obj[:end_at]   = end_at
          obj
        end

      end
    end
  end
end