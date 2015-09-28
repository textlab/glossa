require 'rglossa/query_error'
require 'rglossa/incompatible_metadata_error'

module Rglossa
  module SearchEngines
    class CwbSearch < Search

      def query_info
        @query_info ||= {
          cwb_corpus_name: corpus.code.upcase,

          # The query will be saved under a name composed of the name of the
          # corpus followed by the database ID of the search object
          named_query: corpus.code.upcase + rid.to_s.split(":").last
        }
      end


      def run_queries(cut = nil)
        named_query = query_info[:named_query]

        cwb_corpus_name = get_cwb_corpus_name

        query_str = corpus.multilingual? ? build_multilingual_query : build_monolingual_query

        if metadata_value_ids.empty?
          query_commands = "#{named_query} = #{query_str}"
        else
          # Print corpus positions of texts matching the metadata selection to a file marked with
          # the database ID of the search object
          positions_filename = "#{Dir.tmpdir}/positions_#{id}"
          text_class = if corpus.speech_corpus?
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
        step_cut = cut || max_hits
        query_commands += " cut #{step_cut}" if step_cut

        commands = [
          %Q{set DataDirectory "#{Dir.tmpdir}"},
          cwb_corpus_name,
          query_commands,
          "save #{named_query}",
          "size Last"
        ]
        self.num_hits = run_cqp_commands(commands).to_i
        run_sql("UPDATE #{rid} SET num_hits = ?", num_hits)
      end


      def get_results(start, stop, options = {})
        extra_attributes = options[:extra_attributes] || %w(lemma pos type)

        s_tag = corpus.s_tag || 's'
        s_tag_id = corpus.s_tag_id || "#{s_tag}_id"
        context_size = corpus.context_size || default_context_size
        commands = [
          %Q{set DataDirectory "#{Dir.tmpdir}"},
          get_cwb_corpus_name,  # necessary for the display of id tags to work
          "set Context #{context_size} #{s_tag}",
          'set LD "{{"',
          'set RD "}}"',
          "show +#{s_tag_id}"]

        if corpus.multilingual? && query_array.size > 1
          # Add commands to show aligned text for each additional language included in the search
          short_name = corpus_short_name.downcase
          commands << "show " +
            query_array.drop(1).map { |q| "+#{short_name}_#{q[:lang]}" }.join(' ')
        end

        if extra_attributes.present?
          # TODO: Handle multilingual corpora - here we just take the first language
          if corpus.multilingual?
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
          sort_attr = options[:sort_by] == 'headword_len' ? 'headword_len' : 'word'
          sort_by = case options[:sort_by]
                      when 'match' then 'match'
                      when 'left' then 'match[-1]'
                      when 'right' then 'matchend[1]'
                      when 'headword_len' then 'match'
                    end
          commands << "sort #{query_info[:named_query]} by #{sort_attr} on #{sort_by}"
        end

        commands << "cat #{query_info[:named_query]} #{start} #{stop}"

        res = run_cqp_commands(commands).split("\n")

        # Remove the beginning of the search result, which will be a position number in the
        # case of a monolingual result or the first language of a multilingual result, or
        # an arrow in the case of subsequent languages in a multilingual result.
        res.map! { |r| r.sub(/^\s*\d+:\s*/, '').sub(/^-->.+?:\s*/, '') }

        # When the match includes the first or last token of the s unit, the XML tag surrounding
        # the s unit is included inside the match braces (this should probably be considered a bug
        # in CQP). We need to fix that.
        res.map! { |r| r.sub(/\{\{(<#{s_tag_id}\s+.+?>)/, '\1{{').sub(/(<\/#{s_tag_id}>)\}\}/, '}}\1')}

        transform_results(res)
      end


      def count
        query_str = corpus.multilingual? ? build_multilingual_query : build_monolingual_query
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
        Tempfile.open('cqp', encoding: corpus.encoding) do |command_file|
          commands.map! { |cmd| cmd.end_with?(';') ? cmd : cmd + ';' }
          command_file.puts commands
          command_file.rewind
          puts commands

          cqp_pipe = open("| cqp -c -f#{command_file.path}", external_encoding: corpus.encoding)
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
        if corpus.multilingual?
          # The CWB corpus we select before running our query will be the one named by the
          # short_name attribute of the corpus plus the name of the language of the first
          # submitted query row (e.g. RUN_EN).
          "#{query_info[:cwb_corpus_name]}_#{query_array.first[:lang].upcase}"
        else
          query_info[:cwb_corpus_name]
        end
      end


      def build_monolingual_query
        # For monolingual queries, the query expressions are joined together with '|' (i.e., "or")
        q = query_array.map { |q| q["query"] }
        if q.size > 1
          q = q.map { |part| "(#{part})"}.join(' | ')
        else
          q = q.first.to_s
        end
        q
      end


      def build_multilingual_query
        if query_array.size > 1
          # Add any queries in aligned languages to the first one. For instance, a search for "she"
          # in RUN_EN aligned with "hun" in RUN_NO and also aligned with RUN_RU (without any query string)
          # will result in the following query:
          # "she" :RUN_NO "hun" :RUN_RU [];
          query_array.drop(1).reduce(query_array.first[:query]) do |accumulated_query, aligned_query|
            aq = aligned_query[:query]
            q = if aq.present? and aq != '""' then aq else '[]' end
            "#{accumulated_query} :#{query_info[:cwb_corpus_name]}_#{aligned_query[:lang].upcase} #{q}"
          end
        else
          query_array.first[:query]
        end
      end


      def transform_results(res)
        res.map { |r| {text: r } }
      end
    end
  end
end
