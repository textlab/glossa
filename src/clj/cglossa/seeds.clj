(ns cglossa.seeds
  (:require [datomic.api :refer [transact connect tempid]]
            [datomic-schema.schema :refer [part schema fields generate-parts generate-schema]]
            [cglossa.data-import.core :as data-import]
            [cglossa.models.core :as models]))

(defn dbschema []
  [(schema corpus
           (fields
             [name :string]
             [short-name :string :unique-identity :indexed]))

   (schema search
           (fields
             [corpus :ref :one]
             [queries :string :many]))])

(defn import-corpora []
  (data-import/tsv->tx-data "resources/data/corpora.tsv" "corpus"))

(defn seed []
  (let [url models/db-uri
        conn (connect url)]
    (transact conn (generate-schema tempid (dbschema)))
    (transact conn (import-corpora))))
