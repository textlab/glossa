module Rglossa
  module Speech
    class WaveformPlayerController < ActionController::Base
      TMP_DIR = Rails.root.join(Rails.public_path, "tmp_waveforms")
      def show
        Dir.mkdir TMP_DIR unless Dir.exists? TMP_DIR
        #$path = escapeshellcmd($_GET['path']);
        #$movie_loc = escapeshellcmd(preg_replace('/\.mov$/', '.mp4', preg_replace('/^.*\/mp4:/', "mp4:", $_GET['path'] . $_GET['movie_loc'])));
        #$local_path = escapeshellcmd($_GET['local_path']);
        corpus_id = params[:corpus_id]
        corpus = Corpus.find_by_id(corpus_id)
        line_key = params[:line_key]
        start = params[:start]
        stop = params[:stop]
        movie_loc = "%s_800.mp4" % corpus.media_files.where("line_key_begin <= ? AND ? <= line_key_end",
                                                            line_key, line_key).limit(1).first.basename.rstrip
        @file = Digest::SHA256.hexdigest("#{corpus_id}@#{movie_loc}@#{start}@#{stop}");
        local_path = Rails.root.join(Rails.public_path, corpus.media_path || "media/#{corpus.short_name}", "audio")
        fname = Rails.root.join(TMP_DIR, @file)

        start_time = sprintf("%d.%02d.%d", start.to_i / 60, start.to_i % 60, start.gsub(/^[^.]*(\.|$)/, "").to_i)
        stop_time = sprintf("%d.%02d.%d", stop.to_i / 60, stop.to_i % 60, stop.gsub(/^[^.]*(\.|$)/, "").to_i)
        Process.wait spawn("mp3splt", Rails.root.join(local_path, movie_loc).to_s, start_time, stop_time,
                           "-d", TMP_DIR.to_s, "-o", @file, {:in => :close})
        Process.wait spawn("ffmpeg", "-i", "#{fname}.mp3", "-ac", "1", "#{fname}.wav", {:in => :close})

#        if (substr($movie_loc, -4) == ".mp3")
#        end
##        } else {
##          if (!file_exists("$fname.flv") || filesize("$fname.flv") == 0) {
##            print(`rtmpdump -r $path -y $movie_loc -A $start -B $stop -o $fname.flv`);
##          }
##          if (!file_exists("$fname.mp3")) {
##            print(`ffmpeg -i $fname.flv -ac 1 $fname.wav`);
##            print(`lame --quiet $fname.wav $fname.mp3`);
##          } else {
##            touch("$fname.mp3");
##          }
##        }

        if (!File.exists?("#{fname}-0-wave.jpg"))
          if (!File.exists?("#{fname}.wav"))
            Process.wait spawn("ffmpeg", "-i", "#{fname}.flv", "-ac", "1", "#{fname}.wav", {:in => :close})
          end
##no server start
#          Process.wait spawn({"PYTHONPATH" => "/path/to/waveforms/snack/lib/python2.6/site-packages",
#                  "TCLLIBPATH" => "/path/to/waveforms/snack/lib/snack2.2"},
#                  "xvfb-run", "-s", "-screen 0 8640x216x16", "/path/to/waveforms/genwaveform.py",
#                  "#{fname}.wav", fname, {:in => :close})
##no server stop
##client/server start
          fp = TCPSocket.new '127.0.0.1', 32146
          fp.write("#{@file}.wav\n")
          until fp.eof
            fp.read
          end
          fp.close
##client/server stop
        end

        i = 0
        @basenames = []
        while File.exists?("#{fname}-#{i}-pitch.png")
          @basenames.push "#{@file}-#{i}"
          i += 1
        end
        @basenames.each do |basename|
          FileUtils.touch "#{TMP_DIR}/#{basename}-wave.jpg"
          FileUtils.touch "#{TMP_DIR}/#{basename}-fmt.png"
          FileUtils.touch "#{TMP_DIR}/#{basename}-pitch.png"
        end

        FileUtils.rm_f "#{fname}.wav"
#        FileUtils.rm_f("#{fname}.flv");

        max_i = 0
        @total_imgwidth = 0
        @imgwidths = []
        i = 0
        @basenames.each do |basename|
          max_i = i
          sz = FastImage.size("#{TMP_DIR}/#{basename}-pitch.png")
          @total_imgwidth += sz[0]
          @imgwidths[i] = sz[0]
        end
      end
    end
  end
end
