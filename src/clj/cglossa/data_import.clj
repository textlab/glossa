(ns cglossa.data-import
  (:require [clojure.string :as str]
            [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [environ.core :as environ]
            [me.raynes.conch :as conch]
            [me.raynes.fs :as fs]))

(defn import-corpora []
  (let [tsv-path    "resources/data/corpora.tsv"
        etl-path    (:oetl environ/env)
        config-path (.getPath (fs/absolute "resources/data/corpus.json"))]
    (assert etl-path (str "Please set the OETL environment variable to the path "
                          "to the OrientDB script oetl.sh."))
    (with-open [file (io/reader tsv-path)]
      (let [[headers & data] (csv/read-csv file :separator \tab)]
        (assert (= ["name" "code"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'name' and 'code'."))
        (println etl-path)
        (conch/let-programs [etl etl-path]
                            (etl config-path {:seq true}))))))
