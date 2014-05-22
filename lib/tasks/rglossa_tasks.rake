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


    desc "Copy files to application"
    task :copy_files do
      print "Copying layout file..."

      source = Dir["#{Rglossa::Engine.root}/app/views/layouts/application.html.erb"]
      dest   = "#{Rails.root}/app/views/layouts"
      FileUtils.cp(source, dest)

      puts "done."

      print "Copying application.js..."

      source = Dir["#{Rglossa::Engine.root}/lib/copy_to_app/application.js"]
      dest   = "#{Rails.root}/app/assets/javascripts"
      FileUtils.cp(source, dest)

      puts "done."
    end

  end

end
