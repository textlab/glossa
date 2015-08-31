# cglossa


## Development

### Quick start:
The first time:
```sh
npm install -g bower
bower install
```

Start a REPL (in a terminal: `lein repl`, or from Emacs: open a
clj/cljs file in the project, then do `M-x cider-jack-in`. Make sure
CIDER is up to date).

In the REPL do

```clojure
(run)
```

The call to `(run)` starts the webserver at port
10555, 

Start the figwheel REPL: `lein figwheel` (if you have rlwrap installed, run
`rlwrap lein figwheel` to get line editing, persistent history and completion).


When you see the line `Successfully compiled "resources/public/app.js"
in 21.36 seconds.`, you're ready to go. Browse to
`http://localhost:10555` and enjoy.

## License

Copyright © 2015 The Text Laboratory, University of Oslo

Distributed under the <a href="http://www.opensource.org/licenses/MIT">MIT License</a>.
