require "rglossa/thor_utils"

module Rglossa
  class LineKeys < Thor

    include ::Rglossa::ThorUtils

    desc "dump", "Dump line keys for media files from the segments table in old Glossa"
    method_option :database, default: "glossa",
                  desc: "The database used by old Glossa"
    method_option :user, default: "root",
                  desc: "A database user with permissions to read the old Glossa database"
    method_option :corpus, required: true,
                  desc: "The CWB ID of the corpus (i.e., the name of its registry file)"
    def dump
      setup
      return unless corpus

      sql = "SELECT id, audio_file FROM #{line_keys_table} INTO OUTFILE '#{line_keys_file}'"
      say "Dumping line keys from #{line_keys_table}:"
      run_sql_command(line_keys_file, sql)
    end


    desc "import", "Import line keys for media files"
    method_option :corpus, required: true,
                  desc: "The CWB ID of the corpus (i.e., the name of its registry file)"
    method_option :remove_existing, type: :boolean,
                  desc: "Remove existing values for this corpus before import?"
    def import
      setup
      return unless corpus

      if options[:remove_existing]
        print "Removing existing line keys for this corpus..."
        ActiveRecord::Base.connection.execute(
            "DELETE FROM rglossa_media_files WHERE corpus_id = #{corpus_id}")
        puts " done"
      end

      print "Importing line keys..."
      lines = []
      current_line_key = nil
      current_basename = nil

      File.foreach(line_keys_file) do |line|
        current_line_key, basename = line.split("\t")
        current_line_key = current_line_key.to_i
        if basename != current_basename
          if current_basename
            lines.last[:line_key_end] = current_line_key - 1
          end
          current_basename = basename
          lines << {line_key_begin: current_line_key, basename: current_basename}
        end
      end

      lines.last[:line_key_end] = current_line_key
      corpus.media_files.create!(lines)
      puts " done"
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
