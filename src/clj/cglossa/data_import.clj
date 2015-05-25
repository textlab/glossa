(ns cglossa.data-import
  (:require [clojure.string :as str]
            [clojure.data.csv :as csv]
            [clojure.java.io :as io]
            [environ.core :as environ]
            [me.raynes.conch :as conch]
            [me.raynes.fs :as fs]
            [cheshire.core :as cheshire]))

(def ^:private corpora-config-template
  {:begin        [{:console
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
                   :classes [{:name "Corpus", :extends "V"}],
                   :indexes [{:class "Corpus", :fields ["code:string"], :type "UNIQUE"}]}}})

(def ^:private metadata-categories-config-template
  {:begin        [{:console
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
                   :indexes [{:class "Corpus", :fields ["code:string"], :type "UNIQUE"}
                             {:class "MetadataCategory", :fields ["code:string"], :type "UNIQUE"}
                             {:class "MetadataCategory", :fields ["corpus_cat:string"], :type "UNIQUE"}]}}})

(def ^:private tids-config-template
  {:begin        [{:console
                   {:commands
                    ["CONNECT remote:localhost/Glossa admin admin;"
                     "TRUNCATE CLASS MetadataValue;"
                     "TRUNCATE CLASS HasMetadataValue;"]}}],
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
                  {:dbURL   "remote:localhost/Glossa",
                   :dbType  "graph",
                   :classes [{:name "MetadataCategory", :extends "V"}
                             {:name "MetadataValue", :extends "V"}
                             {:name "HasMetadataValue", :extends "E"}],
                   :indexes [{:class "MetadataCategory", :fields ["corpus_cat:string"], :type "UNIQUE"}]}}})

(def ^:private metadata-values-config-template
  {:source       {:file {:path :WILL-BE-REPLACED}},
   :extractor    {:row {}},
   :transformers [{:csv {:separator "\t"}}
                  {:vertex {:class "MetadataValue"}}
                  {:edge
                   {:class                "HasMetadataValue",
                    :lookup               "MetadataCategory.corpus_cat",
                    :joinFieldName        "corpus_cat",
                    :direction            "in"
                    :unresolvedLinkAction "ERROR"}}],
   :loader       {:orientdb
                  {:dbURL   "remote:localhost/Glossa",
                   :dbType  "graph",
                   :classes [{:name "MetadataCategory", :extends "V"}
                             {:name "MetadataValue", :extends "V"}
                             {:name "HasMetadataValue", :extends "E"}],
                   :indexes [{:class  "MetadataCategory",
                              :fields ["corpus_cat:string"],
                              :type   "UNIQUE"}]}}})

(defn- read-csv [file]
  (csv/read-csv file :separator \tab :quote \^))

(defn- write-csv [file data]
  (csv/write-csv file data :separator \tab))

(defn- run-etl [config-path]
  (let [etl-path (:oetl environ/env)]
    (assert etl-path (str "Please set the OETL environment variable to the path "
                          "to the OrientDB script oetl.sh."))
    (conch/let-programs [etl etl-path]
                        (etl config-path {:seq true}))))

(defn- modify-corpora-config! [config-path tsv-path]
  (spit config-path
        (-> corpora-config-template
            (assoc-in [:source :file :path] tsv-path)
            (cheshire/generate-string {:pretty true}))))

(defn- modify-metadata-categories-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_categories/" corpus ".tsv")
                          io/resource
                          .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      ;; Prepend a column with the code ("short name") for the corpus and
      ;; the category combined, which will be used to create edges from
      ;; the category to its values when we import the latter.
      (let [[orig-headers & orig-rows] (read-csv orig-tsv-file)
            headers (cons "corpus_cat" orig-headers)
            rows    (map #(cons (str corpus "_" (first %)) %) orig-rows)]
        (assert (= ["corpus_cat" "code" "name"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'code' and 'name'."))
        (write-csv tsv-file (cons headers rows))))))

(defn- modify-metadata-categories-config! [corpus config-path tsv-path]
  (spit config-path (-> metadata-categories-config-template
                        (assoc-in [:source :file :path] tsv-path)
                        (assoc-in [:transformers 2 :edge :joinValue] corpus)
                        (cheshire/generate-string {:pretty true}))))

(defn- create-tid-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_values/" corpus ".tsv")
                          io/resource
                          .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      (let [[headers & rows] (read-csv orig-tsv-file)
            tid-header (first headers)]
        (assert (= "tid" tid-header)
                (str "Format error: Expected first line to contain column headers "
                     "with 'tid' (text ID) as the first header."))
        (write-csv tsv-file (cons ["corpus_cat" "value"]
                                  (map (fn [row]
                                         [(str corpus "_tid") (first row)])
                                       rows)))))))

(defn- modify-tid-config! [corpus config-path tsv-path]
  (spit config-path (-> tids-config-template
                        (assoc-in [:source :file :path] tsv-path)
                        (assoc-in [:transformers 2 :edge :joinValue] (str corpus "_tid"))
                        (cheshire/generate-string {:pretty true}))))

(defn- modify-metadata-values-tsv! [corpus tsv-path]
  (let [orig-tsv-path (-> (str "data/metadata_values/" corpus ".tsv")
                          io/resource
                          .getPath)]
    (with-open [orig-tsv-file (io/reader orig-tsv-path)
                tsv-file      (io/writer tsv-path)]
      (let [[headers & rows] (read-csv orig-tsv-file)
            [tid-header & other-headers] headers
            non-blank? (complement str/blank?)]
        (assert (= "tid" tid-header)
                (str "Format error: Expected first line to contain column headers "
                     "with 'tid' (text ID) as the first header."))
        (write-csv tsv-file (->> rows
                                 (mapcat (fn [row]
                                       (map (fn [field header]
                                              [(str corpus "_" header) field])
                                            (rest row) other-headers)))
                                 (filter #(non-blank? (second %)))
                                 (cons ["corpus_cat" "value"])))))))

(defn- modify-metadata-values-config! [config-path tsv-path]
  (spit config-path (-> metadata-values-config-template
                        (assoc-in [:source :file :path] tsv-path)
                        (cheshire/generate-string {:pretty true}))))

(defn import-corpora! []
  (let [tsv-path    (.getPath (io/resource "data/corpora.tsv"))
        config-path (fs/temp-file "corpus_config")]
    (modify-corpora-config! config-path tsv-path)
    (with-open [file (io/reader tsv-path)]
      (let [headers (first (read-csv file))]
        (assert (= ["code" "name"] headers)
                (str "Format error: Expected first line to contain column headers "
                     "and the two columns to be 'code' and 'name'."))
        (run-etl config-path)))))

(defn import-metadata-categories! [corpus]
  (let [tsv-path    (.getPath (fs/temp-file "metadata-cats"))
        config-path (.getPath (fs/temp-file "metadata_cat_config"))]
    (modify-metadata-categories-tsv! corpus tsv-path)
    (modify-metadata-categories-config! corpus config-path tsv-path)
    (run-etl config-path)))

(defn import-metadata-values! [corpus]
  (let [tid-tsv-path      (.getPath (fs/temp-file "tids"))
        other-tsv-path    (.getPath (fs/temp-file "metadata_vals"))
        tid-config-path   (.getPath (fs/temp-file "tid_config"))
        other-config-path (.getPath (fs/temp-file "metadata_val_config"))]
    (create-tid-tsv! corpus tid-tsv-path)
    (modify-tid-config! corpus tid-config-path tid-tsv-path)
    (modify-metadata-values-tsv! corpus other-tsv-path)
    (modify-metadata-values-config! other-config-path other-tsv-path)
    (run-etl tid-config-path)
    (run-etl other-config-path)))
