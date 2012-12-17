require 'rglossa/query_error'

module Rglossa
  class SearchTypes::CwbSearch < Search

    def run_queries
      # TODO: Handle several queries at once
      q = queries[0]
      corpus = q['corpusEdition']
      query = q['query']

      # The query will be saved under a name composed of the name of the
      # corpus edition followed by the database ID of the search object
      named_query = corpus + id.to_s

      commands = [
        %Q{set DataDirectory "#{Dir.tmpdir}"},
        corpus,
        "#{named_query} = #{query}",
        "save #{named_query}",
        "size Last"
      ]

      num_hits = run_cqp_commands(commands)
      update_attribute(:num_hits, num_hits.to_i)
    end


    # Returns a single page of results from CQP
    def get_result_page(page_no)
      q = queries[0]
      corpus = q['corpusEdition']
      named_query = corpus + id.to_s

      # NOTE: page_no is 1-based while cqp uses 0-based numbering of hits
      start = (page_no - 1) * page_size
      stop  = start + page_size - 1
      commands = [
        %Q{set DataDirectory "#{Dir.tmpdir}"},
        "cat #{named_query} #{start} #{stop}"
      ]
      res = run_cqp_commands(commands)
    end

    ########
    private
    ########

    def run_cqp_commands(commands)
      Tempfile.open('cqp') do |command_file|
        commands.map! { |cmd| cmd.end_with?(';') ? cmd : cmd + ';' }
        command_file.puts commands
        command_file.rewind

        output_file = open("| cqp -c -f#{command_file.path}")
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