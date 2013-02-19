module Rglossa
  module ThorUtils

    ########
    private
    ########

    def table
      @table ||= "#{@corpus}text"
    end

    def column_file
      @column_file ||= "#{Rails.root}/tmp/#{table}_columns.txt"
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
