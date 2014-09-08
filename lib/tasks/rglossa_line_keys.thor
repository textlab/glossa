require "rglossa/thor_utils"

module Rglossa
  class LineKeys < Thor

    include ::Rglossa::ThorUtils

    desc "dump", "Dump line keys from the segments table in old Glossa"
    method_option :database, default: "glossa",
                  desc: "The database used by old Glossa"
    method_option :user, default: "root",
                  desc: "A database user with permissions to read the old Glossa database"
    method_option :corpus, required: true,
                  desc: "The CWB ID of the corpus (i.e., the name of its registry file)"

    def dump
      setup

      sql = "SELECT #{corpus_id}, id, audio_file FROM #{line_keys_table} " +
          "INTO OUTFILE '#{line_keys_file}'"
      say "Dumping line keys from #{line_keys_table}:"
      run_sql_command(line_keys_file, sql)
    end

    ########
    private
    ########

    def setup
      # Pull in the Rails app
      require File.expand_path('../../../config/environment', __FILE__)
    end

    def line_keys_file
      @line_keys_file ||= "#{Rails.root}/tmp/#{line_keys_table}_line_keys.tsv"
    end

    def line_keys_table
      @line_keys_table ||= "#{uppercase_corpusname}segments"
    end
  end
end
