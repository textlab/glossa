gem "rglossa", git: "git://github.com/textlab/rglossa.git"

run "bundle install"

run "rm public/index.html"

route "mount Rglossa::Engine => '/'"

rake("railties:install:migrations")
rake("db:migrate")