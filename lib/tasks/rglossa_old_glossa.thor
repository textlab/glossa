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

        table = "#{database}.#{corpus}text"
        outfile = "#{Rails.root}/tmp/#{table}.tsv"

        remove_file(outfile)
        command = %Q{mysql -u #{user} -p #{database} } +
            %Q{-e "SELECT * FROM #{corpus}text INTO OUTFILE '#{outfile}'"}

        puts "Dumping metadata from #{table}:"
        puts command
        system(command)
      end

    end

  end
end
