(ns cglossa.models.schema
  (:require [datomic-schema.schema :refer [part schema fields]]))

(defn dbparts []
  [(part "glossa")])

(defn dbschema []
  [(schema corpus
           (fields
             [name :string]
             [short-name :string :unique-identity]
             [metadata-categories :ref :many :component :indexed]))

   (schema metadata-category
           (fields
             [short-name :string :indexed]
             [name :string]
             [widget-type :enum [:list :range]]
             [values :ref :many :indexed]))

   (schema metadata-value
           (fields
             ; connect the metadata value to one or more text IDs (i.e.
             ; metadata values in the 'tid' category)
             [tids :ref :many :indexed]
             [text-value :string :indexed]
             [numeric-value :long :indexed]
             [bool-value :boolean :indexed]))

   (schema search
           (fields
             [corpus :ref :one]
             [queries :string :many]))])