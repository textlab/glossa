(ns cglossa.models.seeds
  (:require [datomic.api :refer [transact connect tempid]]
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
       (map #(tsv->tx-data % :metadata-category))))

(defn seed []
  (let [url models/db-uri
        conn (connect url)]
    (transact conn (concat
                     (generate-parts tempid (models/dbschema))
                     (generate-schema tempid (models/dbschema))))
    (transact conn (import-corpora))))