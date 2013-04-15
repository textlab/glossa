require "rglossa/thor_utils"

module Rglossa
  module Metadata
    class Import < Thor

      include ::Rglossa::ThorUtils

      desc "categories", "Import metadata categories from _categories and _data files "
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"

      def categories
        setup
        return unless corpus
        create_categories
      end

      #######
      private
      #######

      def setup
        # Pull in the Rails app
        require File.expand_path('../../../config/environment', __FILE__)
      end

      def corpus
        @corpus ||= begin
          corpus = ::Rglossa::Corpus.find_by_short_name(lowercase_corpusname)

          unless corpus
            if yes?("No corpus with short name #{lowercase_corpusname} was found. Create one?")
              full_name = ask("Full name of the corpus:")
              corpus = ::Rglossa::Corpus.create(short_name: lowercase_corpusname, name: full_name)
              unless corpus
                say "Unable to create corpus #{lowercase_corpusname}!", :red
                say $!
              end
            else
              say "No corpus found - aborting!", :red
            end
          end
          corpus
        end
      end

      def create_categories
        category_lines = File.readlines(category_file)
        category_lines.each do |line|
          columns = line.split("\t").map { |col| col.strip }
          short_name = columns[0]
          next if short_name.in?(%w(startpos endpos)) # these are not metadata categories

          # The "human-readable" name of the category can be set in column 2. Defaults to empty string.
          name = columns.size > 1 ? columns[1] : ''

          # The category type ('list', 'short_list' etc.) can be set in column 3. Defaults to 'list'.
          category_type = columns.size > 2 ? columns[2] : 'list'

          # The value type ('text', 'integer' etc.) can be set in column 4. Defaults to 'text'.
          value_type = columns.size > 3 ? columns[3] : 'text'

          if corpus.metadata_categories.find_by_short_name(short_name)
            say_status :skip, "#{short_name} (already exists)"
          else
            say "Creating category #{short_name}"
            corpus.metadata_categories.create!(short_name: short_name,
                                               name: name,
                                               category_type: category_type,
                                               value_type: value_type)
          end
        end
      end

    end
  end
end