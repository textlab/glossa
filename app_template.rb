gem "rglossa", github: "textlab/rglossa"

run "bundle install"

run "rm public/index.html"

route "mount Rglossa::Engine => '/'"

rake("railties:install:migrations")
rake("db:migrate")