module Rglossa
module Speech

class WaveformPlayerController < ActionController::Base
  class <<self
    def before_start
      width = @conf['pixels_per_second'] * 60
      height = @conf['total_height']
      # The display number is the same as the port number
      opts = {:dimensions => "#{width}x#{height}x16", :destroy_at_exit => true}

      # Start Xvfb again if it already exists, as the dimensions may have changed
      headless = begin
        Headless.new(opts.merge({:reuse => false}))
      rescue Headless::Exception
        Headless.new(opts.merge({:reuse => true})).destroy
        Headless.new(opts.merge({:reuse => false}))
      end
      headless.start
    end

    def stop
      server_controller.stop
    end

    def connect
      server_controller.connect &Proc.new
    end

    def conf
      !update_conf? && @conf ? @conf : update_conf
    end

    def abs_path(file)
      Rails.root.join(file).to_s
    end

    private

    def update_conf?
      !@server_controller || !@server_controller.running?
    end

    def update_conf
      @conf = WaveformPlayer.conf
    end

    def server_controller
      if update_conf?
        update_conf
        start_command = "cd %s && exec %s %s %s %s >>%s 2>&1" %
          [Rails.public_path, Rails.root.join('lib/waveforms/genwaveform.py').to_s,
           WaveformPlayer.conf_path, self.abs_path(@conf['pid_file']),
           self.abs_path(@conf['sock_file']), self.abs_path(@conf['log_file'])].
          map {|s| Shellwords.escape s }
        @server_controller = DaemonController.new(
          :identifier => 'Waveform server',
          :before_start => method(:before_start),
          :start_command => start_command,
          :daemonize_for_me => true,
          :ping_command => [:unix, self.abs_path(@conf['sock_file'])],
          :pid_file => self.abs_path(@conf['pid_file']),
          :log_file => self.abs_path(@conf['log_file'])
        )
        @server_controller.restart
        at_exit do
          @server_controller.stop
        end
      end
      @server_controller
    end
  end

  def old_glossa_filename(file, corp)
    file.gsub!(/^[A-Z]*_/, "")
    file.gsub!(/\.wav/i, "")
    file = "BB_" + file.gsub(/_[A-Z]+$/, "") if corp == 'bigbrother'
    file
  end

  def old_glossa_generate_audio(corpus_id, line_key, start, stop, output_path, file, fname)
    conn = ActiveRecord::Base.establish_connection(Rails.configuration.
                                                         database_configuration["oldglossa"]).connection
    res = conn.execute("SELECT audio_file FROM %ssegments WHERE id=%d LIMIT 1" %
                       [corpus_id.upcase, line_key.to_i])
    basename = res.first.first
    ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration[ENV["RAILS_ENV"] ||
                                                                                       "development"])
    path = "rtmp://stream-prod01.uio.no/vod/mp4:uio/hf/ilf/#{corpus_id}/"
    glossa_fn = old_glossa_filename(basename, corpus_id)
    movie_loc = "mp4:uio/hf/ilf/#{corpus_id}/audio/#{glossa_fn}.mp4"
    if (!File.exists?("#{fname}.flv") || File.size("#{fname}.flv") == 0)
      Process.wait spawn("rtmpdump", "-r", path, "-y", movie_loc, "-A", start,
                         "-B", stop, "-o", "#{fname}.flv")
    end
    if !File.exists? "#{fname}.wav"
      Process.wait spawn("ffmpeg", "-i", "#{fname}.flv", "-ac", "1", "#{fname}.wav", {:in => :close})
    end
    if !File.exists? "#{fname}.mp3"
      Process.wait spawn("lame", "--quiet", "#{fname}.wav", "#{fname}.mp3")
    end
  end

  def new_glossa_generate_audio(corpus_id, line_key, start, stop, output_path, file, fname)
    corpus = Corpus.find_by_id(corpus_id)
    movie_loc = "%s.mp3" % corpus.media_files.where("line_key_begin <= ? AND ? <= line_key_end",
                                                    line_key, line_key).limit(1).first.basename.rstrip
    local_path = Rails.root.join(Rails.public_path, corpus.media_path || "media/#{corpus.short_name}", "audio")

    start_time = sprintf("%d.%02d.%d", start.to_i / 60, start.to_i % 60, start.gsub(/^[^.]*(\.|$)/, "").to_i)
    stop_time = sprintf("%d.%02d.%d", stop.to_i / 60, stop.to_i % 60, stop.gsub(/^[^.]*(\.|$)/, "").to_i)
    Process.wait spawn("mp3splt", Rails.root.join(local_path, URI.decode(movie_loc)).to_s, start_time, stop_time,
                       "-d", output_path.to_s, "-o", file, {:in => :close})
    if !File.exists? "#{fname}.wav"
      Process.wait spawn("ffmpeg", "-i", "#{fname}.mp3", "-ac", "1", "#{fname}.wav", {:in => :close})
    end
  end

  def request_waveform(file)
    fp = self.class.connect do
      UNIXSocket.new self.class.abs_path(@conf['sock_file'])
    end
    fp.write("#{params[:width]}\n") if params[:width] =~ /\A\d+\z/
    fp.write("#{file}\n")
    until fp.eof
      fp.read
    end
    fp.close
  end

  def show
    @conf = self.class.conf
    output_path = Rails.root.join(Rails.public_path, @conf['output_dir'])
    Dir.mkdir output_path unless Dir.exists? output_path
    corpus_id = params[:corpus_id]
    line_key = params[:line_key]
    start = params[:start]
    stop = params[:stop]
    params[:oldstart] ||= params[:start]
    params[:oldstop] ||= params[:stop]
    @file = Digest::SHA256.hexdigest("#{corpus_id}@#{line_key}@#{start}@#{stop}");
    fname = Rails.root.join(output_path, @file)
    if (!File.exists?("#{fname}-0-wave.jpg"))
      if corpus_id.match(/^\d+$/)
        new_glossa_generate_audio(corpus_id, line_key, start, stop, output_path, @file, fname)
      elsif corpus_id.match(/^[a-z]+$/)
        old_glossa_generate_audio(corpus_id, line_key, start, stop, output_path, @file, fname)
      else
        raise "Wrong corpus_id: #{corpus_id}"
      end
      request_waveform("#{@file}.wav")
    end

    i = 0
    @basenames = []
    while File.exists?("#{fname}-#{i}-pitch.png")
      @basenames.push "#{@file}-#{i}"
      i += 1
    end

    @basenames.each do |basename|
      FileUtils.touch "#{output_path}/#{basename}-wave.jpg"
      FileUtils.touch "#{output_path}/#{basename}-fmt.png"
      FileUtils.touch "#{output_path}/#{basename}-pitch.png"
    end
    FileUtils.touch("#{fname}.mp3")

    FileUtils.rm_f "#{fname}.wav"
    FileUtils.rm_f "#{fname}.flv"

    @total_imgwidth = 0
    @imgwidths = []
    @basenames.each do |basename|
      sz = FastImage.size("#{output_path}/#{basename}-pitch.png")
      @total_imgwidth += sz[0]
      @imgwidths.push sz[0]
    end
  end
end

end
end
