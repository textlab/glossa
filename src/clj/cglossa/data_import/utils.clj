(ns cglossa.data-import.utils
  (:require [clojure.data.csv :as csv]
            [environ.core :as environ]
            [me.raynes.conch :as conch]))

(defn read-csv [file]
  ;; We don't use quotes around fields (since we separate them by tabs),
  ;; but clojure.data.csv will treat quotes as field separators unless we
  ;; set it to something else - so use a carect, which we are unlikely to
  ;; encounter in texts. Needs a better solution of course (maybe a patch
  ;; to the csv library).
  (csv/read-csv file :separator \tab :quote \^))

(defn write-csv [file data]
  (csv/write-csv file data :separator \tab))

(defn run-etl [config-path]
  (let [etl-path (:oetl environ/env)]
    (assert etl-path (str "Please set the OETL environment variable to the path "
                          "to the OrientDB script oetl.sh."))
    (conch/let-programs [etl etl-path]
                        (etl config-path {:seq true}))))

