namespace "rglossa" do
  namespace "install" do

    desc "Install thor scripts"
    task :thor do
      print "Installing thor scripts... "

      filenames = "rglossa_*.thor"
      source = Dir["#{Rglossa::Engine.root}/lib/tasks/#{filenames}"]
      dest   = "#{Rails.root}/lib/tasks"
      old_files = Dir["#{dest}/#{filenames}"]

      FileUtils.rm(old_files)
      FileUtils.cp(source, dest)

      puts "done."
    end

  end

end
