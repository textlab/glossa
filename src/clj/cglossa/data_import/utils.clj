(ns cglossa.data-import.utils
  (:require [clojure.data.csv :as csv]
            [environ.core :as environ]
            [me.raynes.conch :as conch]))

(defn read-csv [file]
  (csv/read-csv file :separator \tab :quote \^))

(defn write-csv [file data]
  (csv/write-csv file data :separator \tab))

(defn run-etl [config-path]
  (let [etl-path (:oetl environ/env)]
    (assert etl-path (str "Please set the OETL environment variable to the path "
                          "to the OrientDB script oetl.sh."))
    (conch/let-programs [etl etl-path]
                        (etl config-path {:seq true}))))

