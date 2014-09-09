module Rglossa
  module ThorUtils

    include Thor::Actions

    ########
    private
    ########

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

    def table
      @table ||= "#{uppercase_corpusname}#{options[:table_suffix] || 'text'}"
    end

    def uppercase_corpusname
      @uppercase_corpusname ||= options[:corpus].upcase
    end

    def lowercase_corpusname
      @lowercase_corpusname ||= options[:corpus].downcase
    end

    def corpus_id
      @corpus_id = Corpus.find_by_short_name(lowercase_corpusname).id
    end

    def category_file
      @category_file ||= "#{Rails.root}/tmp/#{table}_categories.txt"
    end

    def data_file
      @data_file ||= "#{Rails.root}/tmp/#{table}_data.tsv"
    end

    def run_sql_command(outfile, sql)
      remove_file(outfile)
      command = %Q{mysql -u #{options[:user]} -p #{options[:database]} -e "#{sql}"}
      puts command
      system(command)
    end

  end
end
