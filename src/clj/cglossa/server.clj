(ns cglossa.server
  (:require [clojure.java.io :as io]
            [cglossa.dev :refer [is-dev? inject-devmode-html browser-repl start-figwheel]]
            [compojure.core :refer [GET defroutes routes context]]
            [compojure.route :refer [resources]]
            [compojure.handler :as handler]
            [net.cgrand.enlive-html :refer [deftemplate]]
            [ring.middleware.reload :as reload]
            [ring.middleware.params :refer [wrap-params]]
            [ring.middleware.keyword-params :refer [wrap-keyword-params]]
            [ring.middleware.format :refer [wrap-restful-format]]
            [ring.handler.dump :refer [handle-dump]]
            [prone.middleware :refer [wrap-exceptions]]
            [environ.core :refer [env]]
            [org.httpkit.server :refer [run-server]]
            [cglossa.models.corpora :as corpora]))

(deftemplate page
  (io/resource "index.html") [] [:body] (if is-dev? inject-devmode-html identity))

(defroutes app-routes
  (resources "/")
  (resources "/react" {:root "react"})
  (GET "/corpora/by-short-name" [] corpora/by-short-name)
  (GET "/request" [] handle-dump)
  (GET "/" req (page)))

(def http-handler
  (if is-dev?
    (-> #'app-routes wrap-keyword-params wrap-params wrap-exceptions reload/wrap-reload)
    (-> app-routes wrap-params)))

(defn run [& [port]]
  (defonce ^:private server
    (do
      (if is-dev? (start-figwheel))
      (let [port (Integer. (or port (env :port) 10555))]
        (print "Starting web server on port" port ".\n")
        (run-server http-handler {:port port
                                  :join? false}))))
  server)

(defn -main [& [port]]
  (run port))
