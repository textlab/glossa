module Rglossa
  module Metadata
    class OldGlossa < Thor

      include Thor::Actions

      desc "dump", "Dump data from metadata tables in old Glossa"
      method_option :database, default: "glossa",
                    desc: "The database used by old Glossa"
      method_option :user, default: "root",
                    desc: "A database user with permissions to read the old Glossa database"
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"

      def dump
        setup

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


      desc "convert", "Convert metadata from a dump of the old Glossa format to the RGlossa format"
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"
      method_option :charset, default: 'utf-8',
                    desc: "The character set of the old Glossa data. If different from UTF-8, " +
                        "it will be converted."

      def convert
        setup

        @corpus  = options[:corpus].upcase
        @charset = options[:charset].downcase

        unless @charset.in?('utf-8', 'utf8')
          [column_file, data_file].each do |file|
            tmpfile = "#{file}.tmp"
            system("iconv -f #@charset -t utf-8 #{file} > #{tmpfile}")
            FileUtils.mv(tmpfile, file)
          end
        end

        # More conversions needed?
      end


      ########
      private
      ########

      def setup
        # Pull in the Rails app
        require File.expand_path('../../../config/environment', __FILE__)
      end

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
