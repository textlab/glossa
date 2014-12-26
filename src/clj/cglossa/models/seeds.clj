(ns cglossa.models.seeds
  (:require [datomic.api :as d]
            [datomic-schema.schema :refer [schema fields generate-parts generate-schema]]
            [clojure.java.io :as io]
            [cglossa.data-import.core :refer [import-corpora
                                              import-metadata-categories
                                              import-metadata-values]]
            [cglossa.models.core :as models]
            [cglossa.models.schema :as schema]))

(defn- find-tsv-files [dir]
  "Returns the paths of all tsv files in dir or subdirs"
  (->> (io/file dir)
       file-seq
       (map #(.getPath %))
       (filter #(.endsWith % ".tsv"))))

(defn- path->corpus-short-name [path]
  "Extracts the corpus short name as the base name of a tsv file
  (e.g. 'mycorpus' from '/path/to/mycorpus.tsv'"
  (last (re-find #".+/(.+).tsv$" path)))

(defn- seed-corpora []
  (import-corpora))

(defn- seed-metadata-categories []
  (first (concat (->> (find-tsv-files "resources/data/metadata_categories")
                      (map path->corpus-short-name)
                      (map import-metadata-categories)))))

(defn- seed-metadata-values [db]
  (first (concat (->> (find-tsv-files "resources/data/metadata_values")
                      (map path->corpus-short-name)
                      (map #(import-metadata-values % db))))))
(defn seed []
  (let [url models/db-uri
        conn (d/connect url)]
    (d/transact conn (concat
                       (generate-parts d/tempid (schema/dbparts))
                       (generate-schema d/tempid (schema/dbschema))))
    (d/transact conn (seed-corpora))
    (d/transact conn (seed-metadata-categories))
    @(d/transact-async conn (seed-metadata-values (d/db conn)))
    (println "Finished seeding the database")))
