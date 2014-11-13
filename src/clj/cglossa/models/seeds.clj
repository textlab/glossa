(ns cglossa.models.seeds
  (:require [datomic.api :as d]
            [datomic-schema.schema :refer [generate-parts generate-schema]]
            [clojure.java.io :as io]
            [cglossa.data-import.core :refer [tsv->tx-data]]
            [cglossa.models.core :as models]))

(defn- find-tsv-files [dir]
  (->> (io/file dir)
       file-seq
       (map #(.getPath %))
       (filter #(.endsWith % ".tsv"))))

(defn import-corpora []
  (tsv->tx-data "resources/data/corpora.tsv" :corpus))

(defn import-metadata []
  (->> (find-tsv-files "resources/data/metadata_categories")
       (map #(tsv->tx-data % :metadata-category))
       (map (fn [file-metadata]
              (let [path (-> file-metadata meta :from-path)
                    short-name (last (re-find #".+/(.+).tsv$" path))
                    corpus-attr {:corpus/_metadata-categories [:corpus/short-name short-name]}]
                ; associate the metadata with the appropriate corpus by adding
                ; an attribute with a corpus lookup ref to each metadata value
                (map #(into % corpus-attr) file-metadata))))))

(defn seed []
  (let [url models/db-uri
        conn (d/connect url)]
    (d/transact conn (concat
                     (generate-parts d/tempid (models/dbschema))
                     (generate-schema d/tempid (models/dbschema))))
    (d/transact conn (import-corpora))))