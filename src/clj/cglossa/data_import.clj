(ns cglossa.data-import
  (:require [clojure.string :as str]
            [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [environ.core :as environ]
            [me.raynes.conch :as conch]
            [me.raynes.fs :as fs]))

(defn run-etl [config-path]
  (let [etl-path (:oetl environ/env)]
    (assert etl-path (str "Please set the OETL environment variable to the path "
                          "to the OrientDB script oetl.sh."))
    (conch/let-programs [etl etl-path]
                        (etl config-path {:seq true}))))

(defn import-corpora []
  (let [tsv-path    "resources/data/corpora.tsv"
        config-path (.getPath (fs/absolute "resources/data/corpora.json"))]
    (with-open [file (io/reader tsv-path)]
      (let [[headers & data] (csv/read-csv file :separator \tab)]
        (assert (= ["code" "name"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'code' and 'name'."))
        (run-etl config-path)))))

(defn import-metadata-categories [corpus]
  (let [tsv-path        (-> (str "resources/data/metadata_categories/" corpus ".tsv")
                            fs/absolute
                            .getPath)
        config-template (.getPath (fs/absolute "resources/data/metadata_categories.json"))
        config-file     (fs/temp-file "metadata_cat_config")
        config          (-> (slurp config-template)
                            (str/replace "###CORPUS###" corpus)
                            (str/replace "###TSV-PATH###" tsv-path))]
    (println config-file)
    (spit config-file config)
    (with-open [file (io/reader tsv-path)]
      (let [[headers & data] (csv/read-csv file :separator \tab)]
        (assert (= ["code" "name"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'code' and 'name'."))
        (run-etl config-file)))))
