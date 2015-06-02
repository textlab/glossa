(ns cglossa.server
  (:require [clojure.java.io :as io]
            [cglossa.dev :refer [is-dev? inject-devmode-html]]
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
            [org.httpkit.server :refer [run-server]])
  (:gen-class))

(deftemplate page
             (io/resource "index.html") [] [:body] (if is-dev? inject-devmode-html identity))

(defroutes api-routes
           )

(defroutes app-routes
           (resources "/")
  (GET "/request" [] handle-dump)
  (GET "/" req (page)))

(defroutes db-routes
           (GET "/corpus" [code]
             {:status  200
              :headers {}
              :body    (db/get-corpus code)}))

(def http-handler
  (let [r (routes (wrap-restful-format #'db-routes :formats [:transit-json :json])
                  #'app-routes)
        r (if is-dev? (-> r reload/wrap-reload wrap-exceptions) r)]
    (-> r
        wrap-keyword-params
        wrap-params)))

(defn run [& [port]]
  (defonce ^:private server
           (do
             (let [port (Integer. (or port (env :port) 10555))]
               (print "Starting web server on port" port ".\n")
               (run-server http-handler {:port  port
                                         :join? false}))))
  server)

(defn -main [& [port]]
  (run port))
