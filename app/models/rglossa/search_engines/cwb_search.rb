require 'rglossa/query_error'
require 'rglossa/incompatible_metadata_error'

module Rglossa
  module SearchEngines
    class CwbSearch < Search

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
      def get_result_page(page_no, extra_attributes=['lemma', 'ordkl', 'type'])
        q = queries[0]
        corpus = q['corpusShortName'].upcase
        named_query = corpus + id.to_s

        # NOTE: page_no is 1-based while cqp uses 0-based numbering of hits
        start = (page_no - 1) * page_size
        stop  = start + page_size - 1
        commands = [
          %Q{set DataDirectory "#{Dir.tmpdir}"},
          corpus,  # necessary for "set PrintStructures to work"...
          "set Context s",
          "set PrintStructures s_id"]
        if extra_attributes.present?
          commands << "show " + extra_attributes.map { |a| "+#{a}" }.join(' ')
        end
        commands << "cat #{named_query} #{start} #{stop}"
        run_cqp_commands(commands).split("\n")
      end

      ########
      private
      ########

      def run_cqp_commands(commands)
        corpus = Corpus.find_by_short_name(queries[0]['corpusShortName'].downcase)
        encoding = corpus.encoding

        Tempfile.open('cqp', encoding: encoding) do |command_file|
          commands.map! { |cmd| cmd.end_with?(';') ? cmd : cmd + ';' }
          command_file.puts commands
          command_file.rewind

          output_file = open("| cqp -c -f#{command_file.path}", external_encoding: encoding)
          output_file.readline  # throw away the first line with the CQP version

          result = output_file.read
          if result.include?('PARSE ERROR') || result.include?('CQP Error')
            raise Rglossa::QueryError, result
          end

          command_file.unlink
          result
        end
      end
    end
  end
end
