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
             [tid :ref]                                     ; ref to a value in the tid category
             [text-value :string]
             [numeric-value :long]
             [bool-value :boolean]))

   (schema search
           (fields
             [corpus :ref :one]
             [queries :string :many]))])