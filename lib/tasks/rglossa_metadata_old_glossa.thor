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

        database = options[:database]
        corpus   = options[:corpus].upcase
        user     = options[:user]

        table = "#{corpus}text"

        outfile = "#{Rails.root}/tmp/#{table}_columns.txt"
        sql = "SELECT column_name FROM information_schema.columns WHERE table_name = '#{table}' INTO OUTFILE '#{outfile}'"
        puts "Dumping column names from #{table}:"
        run_sql_command(database, user, outfile, sql)

        outfile = "#{Rails.root}/tmp/#{table}_data.tsv"
        sql = "SELECT * FROM #{corpus}text INTO OUTFILE '#{outfile}'"
        puts "Dumping data from #{table}:"
        run_sql_command(database, user, outfile, sql)
      end

      ########
      private
      ########

      def run_sql_command(database, user, outfile, sql)
        remove_file(outfile)
        command = %Q{mysql -u #{user} -p #{database} -e "#{sql}"}
        puts command
        system(command)
      end

    end

  end
end
