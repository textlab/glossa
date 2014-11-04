(ns cglossa.seeds
  (:require [datomic.api :refer [delete-database create-database transact connect tempid db]]
            [datomic-schema.schema :refer [part schema fields generate-parts generate-schema]]
            [cglossa.server :as server]
            [cglossa.data-import.shared :as data-import]))

(defn dbschema []
  [(schema corpus
           (fields
             [name :string]
             [short-name :string :indexed]))

   (schema search
           (fields
             [corpus :ref :one]
             [queries :string :many]))])

(defn import-corpora []
  (data-import/tsv->tx-data "resources/data/corpora.tsv" "corpus"))

(defn seed []
  (let [url server/db-uri
        conn (connect url)]
    (transact conn (generate-schema tempid (dbschema)))
    (transact conn (import-corpora))))
