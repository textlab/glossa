module Rglossa
  module Speech
    class WaveformPlayerController < ActionController::Base
      class <<self
        attr_accessor :conf, :before_start, :server_controller, :output_dir

        def get_conf
          JSON.parse(File.read(Rails.root.join('config/waveforms.json')))
        end
      end

      @conf = self.get_conf
      @pid_file = Rails.root.join(@conf['pid_file']).to_s
      @log_file = Rails.root.join(@conf['log_file']).to_s
      @output_dir = Rails.root.join(Rails.public_path, @conf['output_dir'])
      @before_start = proc do
        @conf = self.get_conf
        width = @conf['pixels_per_second'] * 60
        height = @conf['total_height']
        # The display number is the same as the port number
        opts = {:display => @conf['listen_port'], :dimensions => "#{width}x#{height}x16"}

        # Start Xvfb again if it already exists, as the dimensions may have changed
        headless = begin
          Headless.new(opts.merge({:reuse => false}))
        rescue Headless::Exception
          Headless.new(opts.merge({:reuse => true})).destroy
          Headless.new(opts.merge({:reuse => false}))
        end
        headless.start
      end
      @server_controller = DaemonController.new(
        :identifier => 'Waveform server',
        :before_start => @before_start,
        :start_command =>
          'cd %s && exec %s %s %s >>%s 2>&1' %
            [Rails.public_path, Rglossa::Engine.root.join('lib/waveforms/genwaveform.py').to_s,
             Rails.root.join('config/waveforms.json').to_s, @pid_file, @log_file].
            map {|s| Shellwords.escape s },
        :daemonize_for_me => true,
        :ping_command => [:tcp, '127.0.0.1', @conf['listen_port']],
        :pid_file => @pid_file,
        :log_file => @log_file
      )

      def old_glossa_filename(file, corp)
        file.gsub!(/^[A-Z]*_/, "")
        file.gsub!(/\.wav/i, "")
        file = "BB_" + file.gsub(/_[A-Z]+$/, "") if corp == 'bigbrother'
        file
      end

      def show
        @conf = self.class.conf
        Dir.mkdir self.class.output_dir unless Dir.exists? self.class.output_dir
        corpus_id = params[:corpus_id]
        line_key = params[:line_key]
        start = params[:start]
        stop = params[:stop]
        @file = Digest::SHA256.hexdigest("#{corpus_id}@#{line_key}@#{start}@#{stop}");
        fname = Rails.root.join(self.class.output_dir, @file)
        if (!File.exists?("#{fname}-0-wave.jpg"))
          if corpus_id.match(/^\d+$/) #new Glossa
            corpus = Corpus.find_by_id(corpus_id)
            movie_loc = "%s_800.mp4" % corpus.media_files.where("line_key_begin <= ? AND ? <= line_key_end",
                                                                line_key, line_key).limit(1).first.basename.rstrip
            local_path = Rails.root.join(Rails.public_path, corpus.media_path || "media/#{corpus.short_name}", "audio")

            start_time = sprintf("%d.%02d.%d", start.to_i / 60, start.to_i % 60, start.gsub(/^[^.]*(\.|$)/, "").to_i)
            stop_time = sprintf("%d.%02d.%d", stop.to_i / 60, stop.to_i % 60, stop.gsub(/^[^.]*(\.|$)/, "").to_i)
            Process.wait spawn("mp3splt", Rails.root.join(local_path, movie_loc).to_s, start_time, stop_time,
                               "-d", self.class.output_dir.to_s, "-o", @file, {:in => :close})
            if !File.exists? "#{fname}.wav"
              Process.wait spawn("ffmpeg", "-i", "#{fname}.mp3", "-ac", "1", "#{fname}.wav", {:in => :close})
            end
          elsif corpus_id.match(/^[a-z]+$/) #old Glossa
            conn = ActiveRecord::Base.establish_connection("oldglossa").connection
            puts("SELECT audio_file FROM %ssegments WHERE id=%d LIMIT 1" %
                               [corpus_id.upcase, line_key.to_i])
            res = conn.execute("SELECT audio_file FROM %ssegments WHERE id=%d LIMIT 1" %
                               [corpus_id.upcase, line_key.to_i])
            basename = res.first.first
            ActiveRecord::Base.establish_connection(ENV["RAILS_ENV"])

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

          fp = self.class.server_controller.connect do
            TCPSocket.new '127.0.0.1', @conf['listen_port']
          end
          fp.write("#{@file}.wav\n")
          until fp.eof
            fp.read
          end
          fp.close
        end

        i = 0
        @basenames = []
        while File.exists?("#{fname}-#{i}-pitch.png")
          @basenames.push "#{@file}-#{i}"
          i += 1
        end
        @basenames.each do |basename|
          FileUtils.touch "#{self.class.output_dir}/#{basename}-wave.jpg"
          FileUtils.touch "#{self.class.output_dir}/#{basename}-fmt.png"
          FileUtils.touch "#{self.class.output_dir}/#{basename}-pitch.png"
        end
        FileUtils.touch("#{fname}.mp3")

        FileUtils.rm_f "#{fname}.wav"
        FileUtils.rm_f "#{fname}.flv"

        max_i = 0
        @total_imgwidth = 0
        @imgwidths = []
        i = 0
        @basenames.each do |basename|
          max_i = i
          sz = FastImage.size("#{self.class.output_dir}/#{basename}-pitch.png")
          @total_imgwidth += sz[0]
          @imgwidths[i] = sz[0]
        end
      end
    end
  end
end