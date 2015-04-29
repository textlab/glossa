(ns cglossa.models.core
  (:require [datomic.api :as d]))

(def db-uri "datomic:free://localhost:4334/glossa")
;(def db-uri "datomic:mem://localhost:4334/glossa")

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

(defn extract-pulled-ids [data]
  "Takes a potentially nested hash map resulting from a Datomic pull
  and extracts all :db/id attribute values from it."
  (->> (for [[k v] data]
         (cond
           (= k :db/id) v                        ; return the id
           (map? v) (extract-pulled-ids v)))     ; process nested map
       flatten                                   ; flatten result of nested maps
       (filter identity)))                       ; remove nils

(defn get-updates [db since ids]
  (sort (d/q '[:find ?tx ?added ?e ?attr ?val
               :in $ $since [?e ...]
               :where
               [$since ?e ?a ?val ?tx ?added]
               [?a :db/ident ?attr]]
             db
             (d/history (d/since db since))
             ids)))
