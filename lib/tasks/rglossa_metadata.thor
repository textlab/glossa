require "rglossa/thor_utils"

module Rglossa
  module Metadata
    class Import < Thor

      include ::Rglossa::ThorUtils

      desc "categories", "Import metadata categories from _categories file "
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"

      def categories
        setup
        return unless corpus
        create_categories
      end


      desc "values", "Import metadata values from _data file "
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"
      method_option :remove_existing, type: :boolean,
                    desc: "Remove existing values for this corpus before import?"

      def values
        setup
        return unless corpus
        import_metadata_values
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
              encoding = ask("Corpus encoding (default = utf-8):")
              encoding = 'utf-8' if encoding.blank?
              corpus = ::Rglossa::Corpus.create(short_name: lowercase_corpusname,
                                                name: full_name,
                                                encoding: encoding)
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

      def import_metadata_values
        # Read category short names from file (typically dumped from old Glossa)
        categories = File.readlines(category_file).map { |line| line.split("\t").first.strip }

        # Find which column contains the text id. This is required.
        tid_col = categories.index('tid')

        unless tid_col
          raise Thor::Error, "No 'tid' (text id) category found! A 'tid' category is necessary " +
              "to link metadata lines to their corresponding corpus texts."
        end

        # Find which columns contain start and end positions for corpus texts (if any)
        startpos_col = categories.index('startpos')
        endpos_col = categories.index('endpos')

        # Map the category names to category objects. Names that have not been imported as
        # categories in RGlossa (such as startpos and endpos) will leave nils in the array,
        # which we can use to skip the corresponding columns in the metadata value lines.
        categories.map! { |cat| corpus.metadata_categories.find_by_short_name(cat) }

        if options[:remove_existing]
          print "Removing existing metadata for this corpus..."
          corpus.corpus_texts.delete_all
          categories.each { |cat| cat.metadata_values.delete_all if cat }
          puts " done"
        end

        total_lines = %x(wc -l #{data_file}).split(' ').first

        # Go through the metadata value lines and create a corpus text for each one. For each
        # column that has a corresponding metadata category, see if a MetadataValue object with
        # this value already exists for the category. If so, fetch it; otherwise create a new one.
        # Finally, associate the value with the corpus text.
        puts "Importing metadata..."
        File.readlines(data_file).each_with_index do |line, lineno|

          if lineno > 0 && lineno % 1000 == 0
            puts "Finished processing #{lineno} of #{total_lines} lines"
          end

          text = corpus.corpus_texts.create!

          # Note: '\N' represents a NULL in MySQL database exports
          columns = line.split("\t").map do |col|
            col.strip!
            col.empty? || col == '\N' ? nil : col
          end

          text.startpos = columns[startpos_col].to_i if startpos_col
          text.endpos   = columns[endpos_col].to_i   if endpos_col

          columns.zip(categories) do |column, category|
            # Skip columns for which no category has been created (e.g. startpos and endpos)
            # as well as empty columns
            next unless category && column

            value = category.get_metadata_value(column)
            text.metadata_values << value
          end

          text.save!
        end
        puts "Done"
      end

    end
  end
end