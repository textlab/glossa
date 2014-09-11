require 'rglossa/query_error'
require 'rglossa/incompatible_metadata_error'

module Rglossa
  module SearchEngines
    class CwbSearch < Search

      def query_info
        @query_info ||= {
          cwb_corpus_name: corpus_short_name.upcase,
          corpus: Corpus.find_by_short_name(corpus_short_name.downcase),

          # The query will be saved under a name composed of the name of the
          # corpus followed by the database ID of the search object
          named_query: corpus_short_name.upcase + id.to_s
        }
      end


      def run_queries
        named_query = query_info[:named_query]

        cwb_corpus_name = get_cwb_corpus_name

        query_str = query_info[:corpus].multilingual? ? build_multilingual_query : build_monolingual_query

        if metadata_value_ids.empty?
          query_commands = "#{named_query} = #{query_str}"
        else
          # Print corpus positions of texts matching the metadata selection to a file marked with
          # the database ID of the search object
          positions_filename = "#{Dir.tmpdir}/positions_#{id}"
          text_class = if query_info[:corpus].speech_corpus?
                         Rglossa::Speech::Speaker
                       else
                         Rglossa::CorpusText
                       end
          text_class.print_positions_matching_metadata(metadata_value_ids, positions_filename)

          raise Rglossa::IncompatibleMetadataError unless File.size?(positions_filename)

          query_commands = [
            "undump #{named_query} < '#{positions_filename}';",
            "#{named_query};",
            "#{named_query} = #{query_str};"].join("\n")
        end
        query_commands += " cut #{max_hits}" if max_hits.present?

        commands = [
          %Q{set DataDirectory "#{Dir.tmpdir}"},
          cwb_corpus_name,
          query_commands,
          "save #{named_query}",
          "size Last"
        ]

        num_hits = run_cqp_commands(commands)
        update_attribute(:num_hits, num_hits.to_i)
      end


      # Returns a single page of results from CQP
      def get_result_page(page_no, options = {})
        extra_attributes = options[:extra_attributes] || %w(lemma pos type)
        corpus = query_info[:corpus]

        # NOTE: page_no is 1-based while cqp uses 0-based numbering of hits
        start = (page_no - 1) * page_size
        stop  = start + page_size - 1
        s_tag = corpus.s_tag || 's'
        s_tag_id = corpus.s_tag_id || "#{s_tag}_id"
        commands = [
          %Q{set DataDirectory "#{Dir.tmpdir}"},
          get_cwb_corpus_name,  # necessary for the display of id tags to work
          "set Context #{default_context_size} #{s_tag}",
          'set LD "{{"',
          'set RD "}}"',
          "show +#{s_tag_id}"]

        if corpus.multilingual? && queries.size > 1
          # Add commands to show aligned text for each additional language included in the search
          short_name = corpus_short_name.downcase
          commands << "show " + queries.drop(1).map { |q| "+#{short_name}_#{q[:lang]}" }.join(' ')
        end

        if extra_attributes.present?
          # TODO: Handle multilingual corpora - here we just take the first language
          if corpus.langs.present?
            pos_attr = corpus.langs.first[:tags]['attr']
            commands << "show " + extra_attributes.map { |a| "+#{a == 'pos' ? pos_attr : a}" }.join(' ')
          else
            commands << "show " + extra_attributes.map { |a| "+#{a}" }.join(' ')
          end
        end

        if corpus.extra_cwb_attrs.present?
          commands << "show " + corpus.extra_cwb_attrs.join(' ')
        end

        if options[:sort_by] && options[:sort_by] != 'position'
          sort_by = case options[:sort_by]
                      when 'match' then 'match'
                      when 'left' then 'match[-1]'
                      when 'right' then 'matchend[1]'
                    end
          commands << "sort #{query_info[:named_query]} by word on #{sort_by}"
        end

        commands << "cat #{query_info[:named_query]} #{start} #{stop}"

        res = run_cqp_commands(commands).split("\n")

        # Remove the beginning of the search result, which will be a position number in the
        # case of a monolingual result or the first language of a multilingual result, or
        # an arrow in the case of subsequent languages in a multilingual result.
        res.map! { |r| r.sub(/^\s*\d+:\s*/, '').sub(/^-->.+?:\s*/, '') }
        res
      end


      def count
        query_str = query_info[:corpus].multilingual? ? build_multilingual_query : build_monolingual_query
        commands = [
          get_cwb_corpus_name,
          query_str,
          "size Last"
        ]
        run_cqp_commands(commands).split("\n").first.to_i
      end


      ########
      private
      ########

      def default_context_size
        1
      end

      def run_cqp_commands(commands)
        encoding = query_info[:corpus].encoding

        Tempfile.open('cqp', encoding: encoding) do |command_file|
          commands.map! { |cmd| cmd.end_with?(';') ? cmd : cmd + ';' }
          command_file.puts commands
          command_file.rewind

          cqp_pipe = open("| cqp -c -f#{command_file.path}", external_encoding: encoding)
          cqp_pipe.readline  # throw away the first line with the CQP version

          result = cqp_pipe.read
          cqp_pipe.close
          if result.include?('PARSE ERROR') || result.include?('CQP Error')
            raise Rglossa::QueryError, result
          end

          command_file.unlink
          result
        end
      end


      def get_cwb_corpus_name
        if query_info[:corpus].multilingual?
          # The CWB corpus we select before running our query will be the one named by the
          # short_name attribute of the corpus plus the name of the language of the first
          # submitted query row (e.g. RUN_EN).
          "#{query_info[:cwb_corpus_name]}_#{queries.first[:lang].upcase}"
        else
          query_info[:cwb_corpus_name]
        end
      end


      def build_monolingual_query
        # For monolingual queries, the query expressions are joined together with '|' (i.e., "or")
        q = queries.map { |q| q[:query] }
        if q.size > 1
          q = q.map { |part| "(#{part})"}.join(' | ')
        else
          q = q.first.to_s
        end
        q
      end


      def build_multilingual_query
        if queries.size > 1
          # Add any queries in aligned languages to the first one. For instance, a search for "she"
          # in RUN_EN aligned with "hun" in RUN_NO and also aligned with RUN_RU (without any query string)
          # will result in the following query:
          # "she" :RUN_NO "hun" :RUN_RU [];
          queries.drop(1).reduce(queries.first[:query]) do |accumulated_query, aligned_query|
            aq = aligned_query[:query]
            q = if aq.present? and aq != '""' then aq else '[]' end
            "#{accumulated_query} :#{query_info[:cwb_corpus_name]}_#{aligned_query[:lang].upcase} #{q}"
          end
        else
          queries.first[:query]
        end
      end

    end
  end
end
