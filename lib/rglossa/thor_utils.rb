module Rglossa
  module ThorUtils

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

    def category_file
      @category_file ||= "#{Rails.root}/tmp/#{table}_categories.txt"
    end

    def data_file
      @data_file ||= "#{Rails.root}/tmp/#{table}_data.tsv"
    end

  end
end
