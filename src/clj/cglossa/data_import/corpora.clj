(ns cglossa.data-import.corpora
  (:require [cheshire.core :as cheshire]
            [clojure.java.io :as io]
            [me.raynes.fs :as fs]
            [clojure.string :as str]
            [cglossa.data-import.utils :as utils]))

(def ^:private config-template
  {:begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS MetadataValue UNSAFE;"
                     "TRUNCATE CLASS MetadataCategory UNSAFE;"
                     "TRUNCATE CLASS Corpus UNSAFE;"]}}]
   :source       {:file {:path "###TSV-PATH###"}}
   :extractor    {:row {}}
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "Corpus"}}]
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa"
                   :dbType              "graph"
                   :wal                 false
                   :useLightweightEdges true
                   :classes             [{:name "Corpus" :extends "V"}]
                   :indexes             [{:class "Corpus" :fields ["code:string"] :type "UNIQUE"}]}}})

(defn- create-config! [config-path tsv-path]
  (spit config-path
        (-> config-template
            (cheshire/generate-string {:pretty true})
            (str/replace "###TSV-PATH###" tsv-path))))

(defn import! []
  (let [tsv-path    (.getPath (io/resource "data/corpora.tsv"))
        config-path (fs/temp-file "corpus_config")]
    (create-config! config-path tsv-path)
    (with-open [file (io/reader tsv-path)]
      (let [headers (first (utils/read-csv file))]
        (assert (= ["code" "name"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'code' and 'name'."))
        (utils/run-etl config-path)))))
