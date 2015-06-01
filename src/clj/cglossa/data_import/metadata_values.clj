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
   :transformers [{:csv {:separator "\t"
                         :columns   ["corpus_cat:string" "value:string"]}}
                  {:vertex {:class "MetadataValue"}}
                  {:edge
                   {:class                "HasMetadataValue"
                    :lookup               "MetadataCategory.corpus_cat"
                    :joinFieldName        "corpus_cat"
                    :direction            "in"
                    :unresolvedLinkAction "HALT"}}]
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
                    :unresolvedLinkAction "HALT"}}]
   :loader       {:orientdb
                  {:dbURL               "remote:localhost/Glossa"
                   :dbType              "graph"
                   :wal                 false
                   :useLightweightEdges true
                   :classes             [{:name "MetadataCategory" :extends "V"}
                                         {:name "MetadataValue" :extends "V"}]
                   :indexes             [{:class  "MetadataCategory"
                                          :fields ["corpus_cat:string"]
                                          :type   "UNIQUE"}
                                         {:class  "MetadataValue"
                                          :fields ["corpus_cat:string" "value:string"]
                                          :type   "UNIQUE"}]}}})

(defn- create-non-tid-config! [config-path tsv-path]
  (spit config-path (-> non-tids-template
                        (cheshire/generate-string {:pretty true})
                        (str/replace "###TSV-PATH###" tsv-path))))

(defn- create-non-tid-tsv! [corpus orig-tsv-path tsv-path]
  (with-open [orig-tsv-file (io/reader orig-tsv-path)
              tsv-file      (io/writer tsv-path)]
    (let [[headers & rows] (utils/read-csv orig-tsv-file)
          [tid-header & other-headers] headers]
      (assert (= "tid" tid-header)
              (str "Format error: Expected first line to contain column headers "
                   "with 'tid' (text ID) as the first header."))
      (utils/write-csv tsv-file (->> rows
                                     (apply map list)       ; Convert rows to columns
                                     rest                   ; Skip 'tid' column
                                     ;; Startpos and endpos are not metadata values; for the
                                     ;; other columns, construct a [header column] vector
                                     (keep-indexed (fn [index col]
                                                     (let [header (get (vec other-headers) index)]
                                                       (when-not (get #{"startpos" "endpos"} header)
                                                         [header col]))))
                                     (mapcat (fn [[header col-vals]]
                                               (map (fn [val] [(str corpus "_" header) val]) col-vals)))
                                     set
                                     (filter (fn [[_ val]]
                                               (not (or (str/blank? val)
                                                        (= "\\N" val)))))
                                     (cons ["corpus_cat" "value"]))))))

(defn- create-tid-config! [corpus config-path orig-tsv-path]
  (with-open [tsv-file (io/reader orig-tsv-path)]
    (let [cats            (first (utils/read-csv tsv-file))
          non-tid-cats    (->> cats
                               rest
                               (filter #(not (get #{"startpos" "endpos"} %1))))
          ;; Create edges from all the non-tid metadata values on the current tsv line
          ;; to the tid value, representing the fact that these values describe the text
          ;; identified by this tid. Note that the non-tid values were created in the
          ;; database in a previous step, by importing a "uniqueified" list of values,
          ;; since we would get lots of duplicate values if we created one value for each
          ;; field on the current tsv line.
          describes-edges (map (fn [cat]
                                 {:edge
                                  {:class                "DescribesText"
                                   :lookup               (str "SELECT from MetadataValue WHERE corpus_cat = '"
                                                              (str corpus "_" cat)
                                                              "' AND value = ?")
                                   :joinFieldName        cat
                                   :direction            "in"
                                   :unresolvedLinkAction "WARNING"}})
                               non-tid-cats)
          field-removals  (map (fn [cat]
                                 {:field {:fieldName cat
                                          :operation "remove"}})
                               non-tid-cats)]
      (spit config-path (-> tids-template
                            ;; Mark all columns except startpos and endpos as strings
                            (update-in [:transformers 0 :csv]
                                       assoc :columns (map (fn [cat] (if (get #{"startpos" "endpos"} cat)
                                                                       cat
                                                                       (str cat ":string")))
                                                           cats))
                            (update-in [:transformers] concat describes-edges field-removals)
                            (cheshire/generate-string {:pretty true})
                            (str/replace "###TSV-PATH###" orig-tsv-path)
                            (str/replace "###CORPUS###" corpus))))))

(defn- fix-fields [row]
  ;; Escape unescaped quotes with a backslash
  (map #(str/replace % #"(?<!\\)\"" "\\\"") row))

(defn- create-tid-tsv! [corpus orig-tsv-path tsv-path]
  (with-open [orig-tsv-file (io/reader orig-tsv-path)
              tsv-file      (io/writer tsv-path)]
    (let [[headers & rows] (utils/read-csv orig-tsv-file)
          [tid-header & other-headers] headers]
      (assert (= "tid" tid-header)
              (str "Format error: Expected first line to contain column headers "
                   "with 'tid' (text ID) as the first header."))
      (utils/write-csv tsv-file (->> rows
                                     (map fix-fields)
                                     (cons (cons "value" other-headers)))))))

(defn import! [corpus]
  (let [orig-tsv-path       (-> (str "data/metadata_values/" corpus ".tsv") io/resource .getPath)
        non-tid-tsv-path    (.getPath (fs/temp-file "metadata_vals"))
        non-tid-config-path (.getPath (fs/temp-file "metadata_val_config"))
        tid-tsv-path        (.getPath (fs/temp-file "tids"))
        tid-config-path     (.getPath (fs/temp-file "tid_config"))]
    (create-non-tid-tsv! corpus orig-tsv-path non-tid-tsv-path)
    (create-non-tid-config! non-tid-config-path non-tid-tsv-path)
    (create-tid-tsv! corpus orig-tsv-path tid-tsv-path)
    (create-tid-config! corpus tid-config-path tid-tsv-path)
    (utils/run-etl non-tid-config-path)
    (utils/run-etl tid-config-path)))
