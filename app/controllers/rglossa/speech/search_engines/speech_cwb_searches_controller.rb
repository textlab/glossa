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
            starttime_attr = corpus.extra_cwb_attrs.detect { |a| a.ends_with?('_starttime') }.sub(/^\+/, '')
            endtime_attr   = corpus.extra_cwb_attrs.detect { |a| a.ends_with?('_endtime')   }.sub(/^\+/, '')
            speaker_attr   = corpus.extra_cwb_attrs.detect { |a| a.ends_with?('_name')   }.sub(/^\+/, '')
          end
          starttime_attr = 'turn_starttime' unless starttime_attr
          endtime_attr   = 'turn_endtime'   unless endtime_attr
          speaker_attr   = 'who_name'       unless speaker_attr

          new_pages = {}
          pages.each do |page_no, page|
            new_pages[page_no] = page.map do |result|
              lines = []
              displayed_lines = []
              speakers = []
              overall_starttime = nil
              overall_endtime = nil

              result.scan(/<#{endtime_attr}\s+([\d\.]+)><#{starttime_attr}\s+([\d\.]+)>(.*?)<\/#{starttime_attr}><\/#{endtime_attr}>/) do |m|
                starttime, endtime, line = m
                lines << line

                overall_starttime ||= starttime
                overall_endtime = endtime

                m2 = line.match(/<#{speaker_attr}\s+(.+?)>(.*?)<\/#{speaker_attr}>/)
                if m2
                  speakers << m2[1]
                  line = m2[2]
                end

                # We asked for a context of several units to the left and right of the unit containing
                # the matching word or phrase, but only the unit with the match (marked by angle
                # brackets) should be included in the search result shown in the result table.
                if line =~ /.+<.+>.+/
                  displayed_lines << line
                end
              end

              media_obj = create_media_obj(overall_starttime, overall_endtime, lines, speakers)

              # The client code expects a colon at the beginning of each result line, so put it in
              {
                  text: ': ' + displayed_lines.join,
                  media_obj: media_obj
              }
            end
          end
          new_pages
        end

        def create_media_obj(overall_starttime, overall_endtime, lines, speakers)
          obj = {
              title: 'hei',
              last_line: '6',
              start_at: '3',
              end_at: '4',
              display_attribute: 'ort',
              mov: {
                  supplied: 'm4v',
                  path: '',
                  movie_loc: 'aaseral_03gm-04gk_800.mp4',
                  start: overall_starttime.to_s,
                  stop: overall_endtime.to_s
              },
              divs: {
                  annotation: {
                  }
              }
          }
          lines.each_with_index do |line, index|
            obj[:divs][:annotation][index] = {
                speaker: speakers.shift || ''
            }
          end
          obj
        end

      end
    end
  end
end