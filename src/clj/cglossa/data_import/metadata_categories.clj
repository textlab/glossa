(ns cglossa.data-import.metadata-categories
  (:require [clojure.java.io :as io]
            [cheshire.core :as cheshire]
            [me.raynes.fs :as fs]
            [cglossa.data-import.utils :as utils]
            [clojure.string :as str]))

(def ^:private config-template
  {:begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS MetadataValue UNSAFE;"
                     "TRUNCATE CLASS MetadataCategory UNSAFE;"]}}]
   :source       {:file {:path "###TSV-PATH###"}}
   :extractor    {:row {}}
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataCategory"}}
                  {:edge
                   {:class                "HasMetadataCategory"
                    :lookup               "Corpus.code"
                    :joinValue            "###CORPUS###"
                    :direction            "in"
                    :unresolvedLinkAction "ERROR"}}]
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa"
                   :dbType              "graph"
                   :wal                 false
                   :useLightweightEdges true
                   :classes             [{:name "Corpus" :extends "V"}
                                         {:name "MetadataCategory" :extends "V"}]
                   :indexes             [{:class "Corpus" :fields ["code:string"] :type "UNIQUE"}
                                         {:class "MetadataCategory" :fields ["code:string"] :type "UNIQUE"}
                                         {:class "MetadataCategory" :fields ["corpus_cat:string"] :type "UNIQUE"}]}}})

(defn- create-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_categories/" corpus ".tsv")
                          io/resource
                          .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      ;; Prepend a column with the code ("short name") for the corpus and
      ;; the category combined, which will be used to create edges from
      ;; the category to its values when we import the latter.
      (let [[orig-headers & orig-rows] (utils/read-csv orig-tsv-file)
            headers (cons "corpus_cat" orig-headers)
            rows    (map #(cons (str corpus "_" (first %)) %) orig-rows)]
        (assert (= ["corpus_cat" "code" "name"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'code' and 'name'."))
        (utils/write-csv tsv-file (cons headers rows))))))

(defn- create-config! [corpus config-path tsv-path]
  (spit config-path (-> config-template
                        (cheshire/generate-string {:pretty true})
                        (str/replace "###TSV-PATH###" tsv-path)
                        (str/replace "###CORPUS###" corpus))))

(defn import! [corpus]
  (let [tsv-path    (.getPath (fs/temp-file "metadata-cats"))
        config-path (.getPath (fs/temp-file "metadata_cat_config"))]
    (create-tsv! corpus tsv-path)
    (create-config! corpus config-path tsv-path)
    (utils/run-etl config-path)))
