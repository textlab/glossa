module Rglossa
  module Metadata
    class OldGlossa < Thor

      desc "dump", "Dump data from metadata tables in old Glossa"
      method_options database: "glossa", user: "root"
      method_option :corpus, required: true

      def dump
        require File.expand_path('../../../config/environment', __FILE__)

        database = options[:database]
        corpus   = options[:corpus].upcase
        user     = options[:user]

        table = "#{database}.#{corpus}text"

        command = %Q{mysql -u #{user} -p #{database} } +
            %Q{-e "SELECT * FROM #{corpus}text INTO OUTFILE '#{Rails.root}/tmp/#{table}.tsv'"}

        puts "Dumping metadata from #{table}:"
        puts command
        system(command)
      end

    end

  end
end
