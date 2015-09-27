require './lib/orientdb'

module Rglossa
  class CorporaController < ApplicationController
    include OrientDb
    respond_to :json, :xml

    def index
      @corpora = many(Corpus, "SELECT FROM Corpus")
    end

    def upload
      corpus_name = params[:corpus].original_filename.downcase.gsub(/\.zip$/, '').gsub(/[^a-z_]/, '')
      if Corpus.where(short_name: corpus_name).length > 0
        flash[:msg] = "The corpus #{corpus_name} already exists, please delete it first"
        flash.keep
        respond_to do |format|
          format.html { redirect_to action: 'list' }
          format.xml  { head :forbidden }
        end
        return
      end
      do_delete(corpus_name)
      Zip::File.open(params[:corpus].path) do |zip_file|
        zip_file.each do |f|
          next unless f.name =~ %r{\Acwb_dat/#{corpus_name.upcase}/} ||
                      f.name =~ %r{\Acwb_reg/#{corpus_name}\z} ||
                      f.name =~ %r{\Amedia/#{corpus_name}/} ||
                      f.name =~ %r{\Aimport/#{corpus_name.upcase}}
          puts f.name
          f_path = File.join('/corpora', f.name)
          FileUtils.mkdir_p(File.dirname(f_path))
          f.extract(f_path)
        end
      end
      corpus_params = YAML.load(File.open("/corpora/cwb_reg/#{corpus_name}").
                           readline.gsub(/^\s*#\s*/, ""))
      c = Corpus.create(name: corpus_params['name'], short_name: corpus_name,
                        encoding: corpus_params['encoding'],
                        config: JSON.parse(JSON.dump(corpus_params['config']), symbolize_names: true),
                        search_engine: corpus_params['search_engine'])
      c.cimdi = corpus_params['cimdi']
      c.save
      if File.exists? "tmp/dumps/#{corpus_name.upcase}segments_line_keys.tsv"
        Process.wait2(spawn("bundle", "exec", "thor", "rglossa:line_keys:import", "--corpus", corpus_name, "--remove-existing"))[1] == 0 or
          raise "rglossa:line_keys:import failed"
      end
      if File.exists? "tmp/dumps/#{corpus_name.upcase}text_categories.txt"
        Process.wait2(spawn("bundle", "exec", "thor", "rglossa:metadata:import:categories", "--corpus", corpus_name,
                            "--speech=#{corpus_params['config']['has_sound'].present? || corpus_params['config']['has_video'].present?}"))[1] == 0 or
          raise "rglossa:metadata:import:categories failed"
        Process.wait2(spawn("bundle", "exec", "thor", "rglossa:metadata:import:values", "--corpus", corpus_name, "--remove-existing",
                            "--speech=#{corpus_params['config']['has_sound'].present? || corpus_params['config']['has_video'].present?}"))[1] == 0 or
          raise "rglossa:metadata:import:values failed"
      end

      flash[:msg] = "The corpus #{corpus_name} has been uploaded"
      flash.keep
      respond_to do |format|
        format.html { redirect_to action: 'list' }
        format.xml  { head :ok }
      end
    end

    def show
      if params[:id]
        @corpus = one(Corpus, "SELECT FROM #TARGET", {target: params[:id]})
      end
    end

    def find_by
      raise "No short_name provided" unless params[:short_name]
      #@corpus = Corpus.where(short_name: params[:short_name]).first
      res = sql_query("SELECT @rid as corpus_rid, name as corpus_name, " +
                      "logo, search_engine, has_phonetic, has_headword_search, " +
                      "$cats.@rid as cat_rids, $cats.code as cat_codes, " +
                      "$cats.name as cat_names " +
                      "FROM Corpus " +
                      "LET $cats = out('HasMetadataCategory') " +
                      "WHERE code = ?",
                      {sql_params: [params[:short_name]]}).first

      metadata_cats = res[:cat_rids].zip(res[:cat_names]).map do |(rid, name)|
        {rid: rid, name: name }
      end

      resp = {
        "corpus" => {
          "rid"                 => res[:corpus_rid],
          "name"                => res[:corpus_name],
          "logo"                => res[:logo],
          "search_engine"       => res[:search_engine] || "cwb",
          "has-phonetic"        => res[:has_phonetic],
          "has-headword-search" => res[:has_headword_search]},
        "metadata-categories" => metadata_cats}
      render json: resp
    end

    def destroy
      corpus_name = params[:id].gsub('/', '')
      do_delete(corpus_name)
      flash[:msg] = "The corpus #{corpus_name} has been removed"
      flash.keep
      respond_to do |format|
        format.html { redirect_to action: 'list' }
        format.xml  { head :ok }
      end
    end

    def cimdi
      @corpus = Corpus.where(short_name: params[:id]).first
      # TODO: Move the language list to a more suitable location
      @langs = {dan: 'Danish', fao: 'Faroese', isl: 'Icelandic',
                nor: 'Norwegian', swe: 'Swedish'}

      if @corpus.cimdi.empty?
        render xml: "No CIMDI metadata found for corpus #{params[:id]}", status: :unprocessable_entity
      end
    end


    ########
    private
    ########

    def do_delete(corpus_name)
      FileUtils.rm_rf ["/corpora/cwb_dat/#{corpus_name.upcase}",
                       "/corpora/cwb_reg/#{corpus_name}",
                       "/corpora/media/#{corpus_name}",
                       *Dir.glob("/corpora/import/#{corpus_name.upcase}*")]
      Corpus.where(short_name: corpus_name).destroy_all
    end

  end
end
