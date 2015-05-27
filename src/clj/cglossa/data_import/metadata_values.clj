(ns cglossa.data-import.metadata-values
  (:require [clojure.java.io :as io]
            [cheshire.core :as cheshire]
            [clojure.string :as str]
            [me.raynes.fs :as fs]
            [cglossa.data-import.utils :as utils]))

(def ^:private non-tids-template
  {:begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS MetadataValue UNSAFE;"]}}]
   :source       {:file {:path "###TSV-PATH###"}}
   :extractor    {:row {}}
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataValue" :skipDuplicates true}}
                  {:edge
                   {:class                "HasMetadataValue"
                    :lookup               "MetadataCategory.corpus_cat"
                    :joinFieldName        "corpus_cat"
                    :direction            "in"
                    :unresolvedLinkAction "ERROR"}}]
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa"
                   :dbType              "graph"
                   :wal                 false
                   :useLightweightEdges true
                   :classes             [{:name "MetadataCategory" :extends "V"}
                                         {:name "MetadataValue" :extends "V"}]
                   :indexes             [{:class  "MetadataCategory"
                                          :fields ["corpus_cat:string"]
                                          :type   "UNIQUE"}]}}})

(def ^:private tids-template
  {:source       {:file {:path "###TSV-PATH###"}}
   :extractor    {:row {}}
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataValue"}}
                  {:edge
                   {:class                "HasMetadataValue"
                    :lookup               "MetadataCategory.corpus_cat"
                    :joinValue            "###CORPUS###_tid"
                    :direction            "in"
                    :unresolvedLinkAction "ERROR"}}]
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa"
                   :dbType              "graph"
                   :wal                 false
                   :useLightweightEdges true
                   :classes             [{:name "MetadataCategory" :extends "V"}
                                         {:name "MetadataValue" :extends "V"}]
                   :indexes             [{:class "MetadataCategory" :fields ["corpus_cat:string"] :type "UNIQUE"}]}}})

(defn- create-non-tids-config! [config-path tsv-path]
  (spit config-path (-> non-tids-template
                        (cheshire/generate-string {:pretty true})
                        (str/replace "###TSV-PATH###" tsv-path))))

(defn- create-non-tids-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_values/" corpus ".tsv") io/resource .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      (let [[headers & rows] (utils/read-csv orig-tsv-file)
            [tid-header & other-headers] headers
            non-blank? (complement str/blank?)]
        (assert (= "tid" tid-header)
                (str "Format error: Expected first line to contain column headers "
                     "with 'tid' (text ID) as the first header."))
        (utils/write-csv tsv-file (->> rows
                                       (apply map list)     ; Convert rows to columns
                                       rest                 ; Skip 'tid' column
                                       ;; Startpos and endpos are not metadata values; for the
                                       ;; other columns, construct a [header column] vector
                                       (keep-indexed (fn [index col]
                                                       (let [header (get (vec other-headers) index)]
                                                         (when-not (get #{"startpos" "endpos"} header)
                                                           [header col]))))
                                       (mapcat (fn [[header col-vals]]
                                                 (map (fn [val] [(str corpus "_" header) val]) col-vals)))
                                       set
                                       (filter #(non-blank? (second %)))
                                       (cons ["corpus_cat" "value"])))))))

(defn- create-tid-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_values/" corpus ".tsv") io/resource .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      (let [[headers & rows] (utils/read-csv orig-tsv-file)
            tid-header (first headers)]
        (assert (= "tid" tid-header)
                (str "Format error: Expected first line to contain column headers "
                     "with 'tid' (text ID) as the first header."))
        (utils/write-csv tsv-file (cons ["corpus_cat" "value"]
                                        (map (fn [row]
                                               [(str corpus "_tid") (first row)])
                                             rows)))))))

(defn- create-tid-config! [corpus config-path tsv-path]
  (spit config-path (-> tids-template
                        (cheshire/generate-string {:pretty true})
                        (str/replace "###TSV-PATH###" tsv-path)
                        (str/replace "###CORPUS###" corpus))))

(defn import! [corpus]
  (let [tid-tsv-path         (.getPath (fs/temp-file "tids"))
        non-tids-tsv-path    (.getPath (fs/temp-file "metadata_vals"))
        tid-config-path      (.getPath (fs/temp-file "tid_config"))
        non-tids-config-path (.getPath (fs/temp-file "metadata_val_config"))]
    (create-non-tids-tsv! corpus non-tids-tsv-path)
    (create-non-tids-config! non-tids-config-path non-tids-tsv-path)
    #_(create-tid-tsv! corpus tid-tsv-path)
    #_(create-tid-config! corpus tid-config-path tid-tsv-path)
    (utils/run-etl non-tids-config-path)
    #_(utils/run-etl tid-config-path)))
