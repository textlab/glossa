(defproject cglossa "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}

  :source-paths ["src/clj"]

  :test-paths ["spec/clj"]

  :dependencies [[org.clojure/clojure "1.6.0"]
                 [org.clojure/clojurescript "0.0-2511" :scope "provided"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]
                 [ring "1.3.2"]
                 [ring/ring-defaults "0.1.2"]
                 [ring-middleware-format "0.4.0"]
                 [compojure "1.2.0"]
                 [enlive "1.1.5"]
                 [reagent "0.5.0"]
                 [environ "1.0.0"]
                 [http-kit "2.1.19"]
                 [prismatic/plumbing "0.3.5" :exclusions [potemkin]]
                 [cljs-ajax "0.3.3"]
                 [prone "0.6.0"]]

  :plugins [[lein-cljsbuild "1.0.3"]
            [lein-environ "1.0.0"]
            [lein-sassc "0.10.0"]
            [lein-auto "0.1.1"]]

  :min-lein-version "2.5.0"

  :uberjar-name "cglossa.jar"

  :jvm-opts ^:replace ["-Xmx1g" "-server"]

  :cljsbuild {:builds {:app {:source-paths ["src/cljs" "target/classes"]
                             :compiler {:output-to     "resources/public/js/app.js"
                                        :output-dir    "resources/public/js/out"
                                        :source-map    "resources/public/js/out.js.map"
                                        :preamble      ["react/react.min.js"]
                                        :externs       ["react/externs/react.js"]
                                        :optimizations :none
                                        :cache-analysis true
                                        :pretty-print  true}}}}

  :sassc [{:src "src/scss/style.scss"
           :output-to "resources/public/css/style.css"}]
  :auto {"sassc"  {:file-pattern  #"\.(scss)$"}}

  :profiles {:dev {:source-paths ["env/dev/clj"]

                   :dependencies [[figwheel "0.1.6-SNAPSHOT"]
                                  [com.cemerick/piggieback "0.1.3"]
                                  [weasel "0.4.2"]
                                  [leiningen "2.5.0"]]

                   :repl-options {:init-ns cglossa.server
                                  :nrepl-middleware [cemerick.piggieback/wrap-cljs-repl]}

                   :plugins [[lein-figwheel "0.1.6-SNAPSHOT"]]

                   :figwheel {:http-server-root "public"
                              :server-port 3449
                              :css-dirs ["resources/public/css"]
                              :open-file-command "idea-opener"}

                   :env {:is-dev true}

                   :cljsbuild {:builds
                               {:app
                                {:source-paths ["env/dev/cljs"]}}}}

             :uberjar {:source-paths ["env/prod/clj"]
                       :hooks [leiningen.cljsbuild  ]
                       :env {:production true}
                       :omit-source true
                       :aot :all
                       :cljsbuild {:builds {:app
                                            {:source-paths ["env/prod/cljs"]
                                             :compiler
                                             {:optimizations :advanced
                                              :pretty-print false}}}}}})
