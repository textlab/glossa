module Rglossa
  module Speech
    module SearchEngines
      class SpeechCwbSearch < ::Rglossa::SearchEngines::CwbSearch

        def run_queries
          # TODO: Handle several queries at once
          q = queries[0]
          corpus = q['corpusShortName'].upcase
          query = q['query']

          # The query will be saved under a name composed of the name of the
          # corpus edition followed by the database ID of the search object
          named_query = corpus + id.to_s

          if metadata_value_ids.empty?
            query_commands = "#{named_query} = #{query}"
          else
            # Print corpus positions of texts matching the metadata selection to a file marked with
            # the database ID of the search object
            positions_filename = "#{Dir.tmpdir}/positions_#{id}"
            CorpusText.print_positions_matching_metadata(metadata_value_ids,
                                                         positions_filename)

            raise Rglossa::IncompatibleMetadataError unless File.size?(positions_filename)

            query_commands = ["undump #{named_query} < '#{positions_filename}';",
                              "#{named_query};",
                              "#{named_query} = #{query};"].join("\n")
          end
          query_commands += " cut #{max_hits}" if max_hits.present?

          commands = [
              %Q{set DataDirectory "#{Dir.tmpdir}"},
              corpus,
              query_commands,
              "save #{named_query}",
              "size Last"
          ]

          num_hits = run_cqp_commands(commands)
          update_attribute(:num_hits, num_hits.to_i)
        end


        # Returns a single page of results from CQP
        def get_result_page(page_no, extra_attributes = %w(lemma pos type))
          q = queries[0]
          cwbCorpusName = q['corpusShortName'].upcase
          corpus = Corpus.find_by_short_name(q['corpusShortName'])
          named_query = cwbCorpusName + id.to_s

          # NOTE: page_no is 1-based while cqp uses 0-based numbering of hits
          start = (page_no - 1) * page_size
          stop  = start + page_size - 1
          s_tag = corpus.s_tag || "s"
          commands = [
              %Q{set DataDirectory "#{Dir.tmpdir}"},
              cwbCorpusName,  # necessary for "set PrintStructures to work"...
              "set Context 7 #{s_tag}",
              "set PrintStructures #{s_tag}_id"]

          if extra_attributes.present?
            # TODO: Handle multilingual corpora - here we just take the first language
            if corpus.langs.present?
              pos_attr = corpus.langs.first[:tags]['attr']
              commands << "show " + extra_attributes.map { |a| "+#{a == 'pos' ? pos_attr : a}" }.join(' ')
            elsif corpus.extra_cwb_attrs
              commands << "show " + corpus.extra_cwb_attrs.join(' ')
            end
          end

          commands << "cat #{named_query} #{start} #{stop}"

          run_cqp_commands(commands).split("\n")
        end
      end
    end
  end
end
