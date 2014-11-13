(ns cglossa.models.core
  (:require [datomic.api :as d]
            [datomic-schema.schema :refer [part schema fields]]))

(def db-uri "datomic:free://localhost:4334/glossa")

(defn dbparts []
  [(part "glossa")])

(defn dbschema []
  [(schema corpus
           (fields
             [name :string]
             [short-name :string :unique-identity]
             [metadata-categories :ref :many :component]))

   (schema metadata-category
           (fields
             [short-name :string]
             [name :string]
             [widget-type :enum [:list :range]]
             [values :ref :many "One or more text-values, bool-values or numeric-values"]
             [text-value :string]
             [bool-value :boolean]
             [numeric-value :long]))

   (schema search
           (fields
             [corpus :ref :one]
             [queries :string :many]))])

(defn current-db []
  (d/db (d/connect db-uri)))

(defn find-by
  "Finds the first entity with the given value for the given Datomic attribute
  (e.g. :person/name) in the given (or by default the current) database."
  ([attr value]
   (find-by attr value (current-db)))
  ([attr value db]
   (let [ids (d/q '[:find ?e :in $ ?a ?v :where [?e ?a ?v]] db attr value)]
     (d/entity db (ffirst ids)))))
