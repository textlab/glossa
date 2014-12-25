(ns cglossa.models.schema
  (:require [datomic-schema.schema :refer [part schema fields]]))

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
             [values :ref :many]))

   (schema metadata-value
           (fields
             ; connect the metadata value to one or more text IDs (i.e.
             ; metadata values in the 'tid' category)
             [tids :ref :many]
             [text-value :string]
             [numeric-value :long]
             [bool-value :boolean]))

   (schema search
           (fields
             [corpus :ref :one]
             [queries :string :many]))])