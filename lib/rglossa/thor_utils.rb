module Rglossa
  module ThorUtils

    include Thor::Actions

    ########
    private
    ########

    def table
      @table ||= "#{uppercase_corpusname}text"
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
