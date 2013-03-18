def install_devise
  generate("devise:install")
  generate("devise", "User")

  devise_sender = ask("Please provide a sender e-mail address to use when sending info to users " +
                          "(in the case of a lost password etc.). Can be changed later in " +
                          "config/initializers/devise.rb:")

  init_file = 'config/initializers/devise.rb'
  text = File.read(init_file)
  text.sub!(/(config.mailer_sender = ").+?"/, %Q(\\1#{devise_sender}"))
  File.write(init_file, text)
end


##############
# Main script
##############

gem "rglossa", github: "textlab/rglossa"
gem "devise", "~> 2.2.3"

run "bundle install"

run "rm public/index.html"

route "mount Rglossa::Engine => '/'"

rake("railties:install:migrations")

install_devise

rake("db:migrate")
