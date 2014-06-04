def install_devise
  generate("devise:install")

  devise_sender = ask("Please provide a sender e-mail address to use when sending info to users " +
                          "(in the case of a lost password etc.). Can be changed later in " +
                          "config/initializers/devise.rb:")

  gsub_file("config/initializers/devise.rb",
            /(config.mailer_sender = ").+?"/,
            %Q(\\1#{devise_sender}"))
end


def configure_react(environment)
  insert_into_file("config/environments/#{environment}.rb",
    "\n" +
    "  config.react.variant = :#{environment}\n" +
    "  config.react.addons = true\n",
    after: "# Settings specified here will take precedence over those in config/application.rb\n")
end


##############
# Main script
##############

gem "rglossa", github: "textlab/rglossa"
gem "devise", "~> 2.2.3"
gem "therubyracer"
gem "thin"
gem "react-rails"

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

configure_react("development")
configure_react("production")
