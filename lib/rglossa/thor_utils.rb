module Rglossa
  module ThorUtils

    ########
    private
    ########

    def table
      @table ||= "#{@corpus}text"
    end

    def category_file
      @column_file ||= "#{Rails.root}/tmp/#{table}_categories.txt"
    end

    def data_file
      @data_file ||= "#{Rails.root}/tmp/#{table}_data.tsv"
    end

    def run_sql_command(outfile, sql)
      remove_file(outfile)
      command = %Q{mysql -u #@user -p #@database -e "#{sql}"}
      puts command
      system(command)
    end

  end
end
