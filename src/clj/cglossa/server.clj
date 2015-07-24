(ns cglossa.server
  (:require [clojure.java.io :as io]
            [compojure.core :refer [GET POST defroutes routes context]]
            [compojure.route :refer [resources]]
            [net.cgrand.enlive-html :refer [deftemplate]]
            [ring.util.response :as response]
            [ring.middleware.reload :as reload]
            [ring.middleware.params :refer [wrap-params]]
            [ring.middleware.keyword-params :refer [wrap-keyword-params]]
            [ring.middleware.json :refer [wrap-json-params]]
            [ring.handler.dump :refer [handle-dump]]
            [prone.middleware :refer [wrap-exceptions]]
            [environ.core :refer [env]]
            [org.httpkit.server :refer [run-server]]
            [clojure.tools.logging :as log]
            [cognitect.transit :as transit]
            [cglossa.db :as db]
            [cglossa.search :as search])
  (:import [java.io ByteArrayOutputStream])
  (:gen-class))

;; Global exception handler. From http://stuartsierra.com/2015/05/27/clojure-uncaught-exceptions
;; Assuming require [clojure.tools.logging :as log]
(defn- set-default-exception-handler! []
  (Thread/setDefaultUncaughtExceptionHandler
    (reify Thread$UncaughtExceptionHandler
      (uncaughtException [_ thread ex]
        (log/error ex "Uncaught exception on" (.getName thread))))))

(defn- transit-response* [body]
  (let [baos   (ByteArrayOutputStream. 2000)
        writer (transit/writer baos :json)
        _      (transit/write writer body)
        res    (.toString baos)]
    (.reset baos)
    (-> (response/response res)
        (response/content-type "application/transit+json")
        (response/charset "utf-8"))))

(defmacro transit-response [fn-call]
  `(try (let [res# ~fn-call]
          (transit-response* res#))
        (catch Exception e#
          (log/error e#)
          {:status 500
           :body   (.toString e#)})))

(deftemplate page (io/resource "index.html") [])

(defroutes app-routes
  (resources "/")
  (GET "/request" [] handle-dump)
  (GET "/" req (page)))

(defroutes db-routes
  (GET "/corpus" [code]
    (transit-response (db/get-corpus code))))

(defroutes search-routes
  (POST "/search" [corpus-id queries]
    (transit-response (search/search corpus-id queries)))

(def http-handler
  (let [r (routes #'db-routes #'search-routes #'app-routes)
        r (if (:is-dev env) (-> r reload/wrap-reload wrap-exceptions) r)]
    (-> r
        wrap-keyword-params
        wrap-json-params
        wrap-params)))

(defn run [& [port]]
  (set-default-exception-handler!)
  (defonce ^:private server
           (do
             (let [port (Integer. (or port (env :port) 10555))]
               (print "Starting web server on port" port ".\n")
               (run-server http-handler {:port  port
                                         :join? false}))))
  server)

(defn -main [& [port]]
  (run port))
