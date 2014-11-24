(ns cglossa.models.core
  (:require [datomic.api :as d]))


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
