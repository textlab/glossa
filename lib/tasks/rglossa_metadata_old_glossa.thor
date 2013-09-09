require "rglossa/thor_utils"

module Rglossa
  module Metadata
    class OldGlossa < Thor

      include Thor::Actions
      include ::Rglossa::ThorUtils

      desc "dump", "Dump data from metadata tables in old Glossa"
      method_option :database, default: "glossa",
                    desc: "The database used by old Glossa"
      method_option :user, default: "root",
                    desc: "A database user with permissions to read the old Glossa database"
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"

      def dump
        setup

        sql = "SELECT column_name FROM information_schema.columns " +
            "WHERE table_name = '#{table}' INTO OUTFILE '#{category_file}'"
        say "Dumping column names from #{table}:"
        run_sql_command(category_file, sql)

        sql = "SELECT * FROM #{uppercase_corpusname}text INTO OUTFILE '#{data_file}'"
        say "Dumping data from #{table}:"
        run_sql_command(data_file, sql)

        # Find line breaks inside fields (escaped by backslashes) and replace them by spaces, since
        # they confuse the import mechanism we will run later on by splitting a single record
        # across several lines.
        gsub_file(data_file, /\\\n/, ' ')

        say "Now specify the type of each (non-text) category in #{category_file}", :yellow
      end


      desc "convert", "Convert metadata from a dump of the old Glossa format to the RGlossa format"
      method_option :corpus, required: true,
                    desc: "The CWB ID of the corpus (i.e., the name of its registry file)"
      method_option :charset, default: 'utf-8',
                    desc: "The character set of the old Glossa data. If different from UTF-8, " +
                        "it will be converted."

      def convert
        setup

        charset = options[:charset].downcase

        unless charset.in?('utf-8', 'utf8')
          [category_file, data_file].each do |file|
            tmpfile = "#{file}.tmp"
            system("iconv -f #{charset} -t utf-8 #{file} > #{tmpfile}")
            FileUtils.mv(tmpfile, file)
          end
        end

        # More conversions needed?
      end

      #######
      private
      #######

      def setup
        # Pull in the Rails app
        require File.expand_path('../../../config/environment', __FILE__)
      end

      def run_sql_command(outfile, sql)
        remove_file(outfile)
        command = %Q{mysql -u #{options[:user]} -p #{options[:database]} -e "#{sql}"}
        puts command
        system(command)
      end

    end

  end
end
