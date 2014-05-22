def install_devise
  generate("devise:install")

  devise_sender = ask("Please provide a sender e-mail address to use when sending info to users " +
                          "(in the case of a lost password etc.). Can be changed later in " +
                          "config/initializers/devise.rb:")

  gsub_file("config/initializers/devise.rb",
            /(config.mailer_sender = ").+?"/,
            %Q(\\1#{devise_sender}"))
end


##############
# Main script
##############

gem "rglossa", github: "textlab/rglossa"
gem "devise", "~> 2.2.3"
gem "therubyracer"

run "bundle install"

rake("rglossa:install:copy_files")

run "rm public/index.html"

route "mount Rglossa::Engine => '/'"

rake("railties:install:migrations")

rake("rglossa:install:thor")

install_devise

rake("db:migrate")

insert_into_file("app/assets/stylesheets/application.css",
                 " *= require rglossa/application\n",
                 after: "*= require_self\n")
