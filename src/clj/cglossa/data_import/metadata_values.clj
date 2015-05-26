(ns cglossa.data-import.metadata-values
  (:require [clojure.java.io :as io]
            [cheshire.core :as cheshire]
            [clojure.string :as str]
            [me.raynes.fs :as fs]
            [cglossa.data-import.utils :as utils]))

(def ^:private tids-template
  {:begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS MetadataValue UNSAFE;"]}}],
   :source       {:file {:path :WILL-BE-REPLACED}},
   :extractor    {:row {}},
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataValue"}}
                  {:edge
                   {:class                "HasMetadataValue",
                    :lookup               "MetadataCategory.corpus_cat",
                    :joinValue            :WILL-BE-REPLACED
                    :direction            "in"
                    :unresolvedLinkAction "ERROR"}}],
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa",
                   :dbType              "graph",
                   :wal                 false,
                   :useLightweightEdges true,
                   :classes             [{:name "MetadataCategory", :extends "V"}
                                         {:name "MetadataValue", :extends "V"}],
                   :indexes             [{:class "MetadataCategory", :fields ["corpus_cat:string"], :type "UNIQUE"}]}}})

(def ^:private metadata-values-template
  {:source       {:file {:path :WILL-BE-REPLACED}},
   :extractor    {:row {}},
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataValue" :skipDuplicates true}}
                  {:edge
                   {:class                "HasMetadataValue",
                    :lookup               "MetadataCategory.corpus_cat",
                    :joinFieldName        "corpus_cat",
                    :direction            "in"
                    :unresolvedLinkAction "ERROR"}}],
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa",
                   :dbType              "graph",
                   :wal                 false,
                   :useLightweightEdges true,
                   :classes             [{:name "MetadataCategory", :extends "V"}
                                         {:name "MetadataValue", :extends "V"}],
                   :indexes             [{:class  "MetadataCategory",
                                          :fields ["corpus_cat:string"],
                                          :type   "UNIQUE"}]}}})

(defn- create-tid-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_values/" corpus ".tsv")
                          io/resource
                          .getPath)]
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
                        (assoc-in [:source :file :path] tsv-path)
                        (assoc-in [:transformers 2 :edge :joinValue] (str corpus "_tid"))
                        (cheshire/generate-string {:pretty true}))))

(defn- create-other-vals-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_values/" corpus ".tsv")
                          io/resource
                          .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      (let [[headers & rows] (utils/read-csv orig-tsv-file)
            [tid-header & other-headers] headers
            non-blank? (complement str/blank?)]
        (assert (= "tid" tid-header)
                (str "Format error: Expected first line to contain column headers "
                     "with 'tid' (text ID) as the first header."))
        (utils/write-csv tsv-file (->> rows
                                       (mapcat (fn [row]
                                                 (map (fn [field header]
                                                        [(str corpus "_" header) field])
                                                      (rest row) other-headers)))
                                       (filter #(non-blank? (second %)))
                                       (cons ["corpus_cat" "value"])))))))

(defn- create-other-vals-config! [config-path tsv-path]
  (spit config-path (-> metadata-values-template
                        (assoc-in [:source :file :path] tsv-path)
                        (cheshire/generate-string {:pretty true}))))

(defn import! [corpus]
  (let [tid-tsv-path      (.getPath (fs/temp-file "tids"))
        other-tsv-path    (.getPath (fs/temp-file "metadata_vals"))
        tid-config-path   (.getPath (fs/temp-file "tid_config"))
        other-config-path (.getPath (fs/temp-file "metadata_val_config"))]
    (create-tid-tsv! corpus tid-tsv-path)
    (create-tid-config! corpus tid-config-path tid-tsv-path)
    (create-other-vals-tsv! corpus other-tsv-path)
    (create-other-vals-config! other-config-path other-tsv-path)
    (utils/run-etl tid-config-path)
    (utils/run-etl other-config-path)))

