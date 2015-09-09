(defproject cglossa "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "Eclipse Public License"
            :url  "http://www.eclipse.org/legal/epl-v10.html"}

  :source-paths ["src/clj"]

  :test-paths ["spec/clj"]

  :dependencies [[org.clojure/clojure "1.7.0"]
                 [org.clojure/clojurescript "1.7.48" :scope "provided"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]
                 [ring "1.3.2"]
                 [ring/ring-defaults "0.1.5"]
                 [ring/ring-json "0.4.0"]
                 [com.cognitect/transit-clj "0.8.275"]
                 [compojure "1.3.4"]
                 [enlive "1.1.5"]
                 [reagent "0.5.1-rc" :exclusions [cljsjs/react]]
                 [cljsjs/react-bootstrap "0.23.7-0"]
                 [cljsjs/jquery "1.9.0-0"]
                 [environ "1.0.0"]
                 [http-kit "2.1.19"]
                 [cljs-http "0.1.35"]
                 [prone "0.8.2"]
                 [com.orientechnologies/orientdb-graphdb "2.1-rc3"]
                 [org.clojure/data.csv "0.1.2"]
                 [me.raynes/conch "0.8.0"]
                 [me.raynes/fs "1.4.6"]
                 [cheshire "5.5.0"]
                 [org.clojure/tools.logging "0.3.1"]
                 [binaryage/devtools "0.3.0"]]

  :plugins [[lein-cljsbuild "1.0.6"]
            [lein-environ "1.0.0"]
            [lein-sassc "0.10.0"]
            [lein-auto "0.1.1"]]

  :min-lein-version "2.5.0"

  :uberjar-name "cglossa.jar"

  :jvm-opts ^:replace ["-Xmx1g" "-server"]

  :main cglossa.server

  :clean-targets ^{:protect false} ["resources/public/js/out"]

  :cljsbuild
  {:builds
   {:app
    {:source-paths ["src/cljs"]
     :compiler     {:output-to            "resources/public/js/out/app.js"
                    :output-dir           "resources/public/js/out"
                    :source-map           "resources/public/js/out/out.js.map"
                    :source-map-timestamp true
                    :optimizations        :none
                    :cache-analysis       true
                    :main                 "cglossa.core"
                    :asset-path           "js/out"
                    :foreign-libs         [{:file     "resources/public/js/select2.js"
                                            :file-min "resources/public/js/select2-min.js"
                                            :provides ["js-select2"]
                                            :requires ["cljsjs.jquery"]}]
                    :externs              ["resources/public/js/externs/select2.ext.js"]
                    :pretty-print         true}}}}

  :sassc [{:src       "src/scss/style.scss"
           :output-to "resources/public/css/style.css"}]
  :auto {"sassc" {:file-pattern #"\.(scss)$"}}

  :profiles {:dev     {:dependencies [[figwheel "0.3.9"]
                                      [com.cemerick/piggieback "0.2.1"]
                                      [org.clojure/tools.nrepl "0.2.10"]
                                      [leiningen "2.5.1"]]

                       :repl-options {:init-ns          cglossa.server
                                      :nrepl-middleware [cemerick.piggieback/wrap-cljs-repl]}

                       :plugins      [[lein-figwheel "0.3.9"]]

                       :figwheel     {:css-dirs          ["resources/public/css"]
                                      :open-file-command "idea-opener"}

                       :env          {:is-dev true}

                       :cljsbuild    {:builds
                                      {:app
                                       {:figwheel {:on-jsload "cglossa.core/main"}}}}}

             :uberjar {:hooks       [leiningen.cljsbuild]
                       :env         {:production true}
                       :omit-source true
                       :aot         :all
                       :cljsbuild   {:builds {:app
                                              {:compiler
                                               {:optimizations :advanced
                                                :pretty-print  false}}}}}})
