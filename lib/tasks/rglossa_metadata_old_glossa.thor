module Rglossa
  module Metadata
    class OldGlossa < Thor

      include Thor::Actions

      desc "dump", "Dump data from metadata tables in old Glossa"
      method_options database: "glossa", user: "root"
      method_option :corpus, required: true

      def dump
        # Pull in the Rails app
        require File.expand_path('../../../config/environment', __FILE__)

        @database = options[:database]
        @corpus   = options[:corpus].upcase
        @user     = options[:user]

        sql = "SELECT column_name FROM information_schema.columns " +
            "WHERE table_name = '#{table}' INTO OUTFILE '#{column_file}'"
        puts "Dumping column names from #{table}:"
        run_sql_command(column_file, sql)

        sql = "SELECT * FROM #{@corpus}text INTO OUTFILE '#{data_file}'"
        puts "Dumping data from #{table}:"
        run_sql_command(data_file, sql)
      end


      desc "convert", "Convert metadata from a dump of the old Glossa format to RGlossa format"
      method_option :corpus, required: true

      def convert
      end

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
end
