(ns cglossa.data-import
  (:require [clojure.string :as str]
            [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [environ.core :as environ]
            [me.raynes.conch :as conch]
            [me.raynes.fs :as fs]
            [cheshire.core :as cheshire]))

(def ^:private corpora-config-template
  {:config       {:log "debug"},
   :begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS Corpus;"]}}],
   :source       {:file {:path :WILL-BE-REPLACED}},
   :extractor    {:row {}},
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "Corpus"}}],
   :loader       {:orientdb
                  {:dbURL   "remote:localhost/Glossa",
                   :dbType  "graph",
                   :classes [{:name "Corpus", :extends "V"}
                             {:name "MetadataCategory", :extends "V"}
                             {:name "HasMetadataCategory", :extends "E"}],
                   :indexes [{:class "Corpus", :fields ["code:string"], :type "UNIQUE"}]}}})

(def ^:private metadata-categories-config-template
  {:config       {:log "debug"},
   :begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS MetadataCategory;"
                     "TRUNCATE CLASS HasMetadataCategory;"]}}],
   :source       {:file {:path :WILL-BE-REPLACED}},
   :extractor    {:row {}},
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataCategory"}}
                  {:edge
                   {:class                "HasMetadataCategory",
                    :lookup               "Corpus.code",
                    :joinValue            :WILL-BE-REPLACED,
                    :unresolvedLinkAction "ERROR"}}],
   :loader       {:orientdb
                  {:dbURL   "remote:localhost/Glossa",
                   :dbType  "graph",
                   :classes [{:name "Corpus", :extends "V"}
                             {:name "MetadataCategory", :extends "V"}
                             {:name "HasMetadataCategory", :extends "E"}],
                   :indexes [{:class "Corpus", :fields ["code:string"], :type "UNIQUE"}]}}})

(defn- run-etl [config-path]
  (let [etl-path (:oetl environ/env)]
    (assert etl-path (str "Please set the OETL environment variable to the path "
                          "to the OrientDB script oetl.sh."))
    (conch/let-programs [etl etl-path]
                        (etl config-path {:seq true}))))

(defn- import-2cols [tsv-path config-path]
  (with-open [file (io/reader tsv-path)]
    (let [headers (first (csv/read-csv file :separator \tab))]
      (assert (= ["code" "name"] headers)
              (str "Format error: Expected first line to contain column headers "
                   "and the two columns to be 'code' and 'name'."))
      (run-etl config-path))))

(defn import-corpora []
  (let [tsv-path    (.getPath (io/resource "data/corpora.tsv"))
        config-path (fs/temp-file "corpus_config")
        config      (-> corpora-config-template
                        (assoc-in [:source :file :path] tsv-path)
                        (cheshire/generate-string {:pretty true}))]
    (spit config-path config)
    (import-2cols tsv-path config-path)))

(defn import-metadata-categories [corpus]
  (let [tsv-path    (-> (str "data/metadata_categories/" corpus ".tsv")
                        io/resource
                        .getPath)
        config-path (fs/temp-file "metadata_cat_config")
        config      (-> metadata-categories-config-template
                        (assoc-in [:source :file :path] tsv-path)
                        (assoc-in [:transformers 2 :edge :joinValue] corpus)
                        (cheshire/generate-string {:pretty true}))]
    (spit config-path config)
    (import-2cols tsv-path config-path)))
