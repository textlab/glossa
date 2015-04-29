(ns cglossa.history-test
  (:require [datomic.api :as d]
            [datomic-schema.schema :refer [part schema fields generate-parts generate-schema]]
            [cglossa.models.core :as models]))

(defn run []
  (let [db-uri models/db-uri
        _ (d/delete-database db-uri)
        _ (d/create-database db-uri)
        conn (d/connect db-uri)
        dbschema [(schema person
                          (fields
                            [first-name :string]
                            [last-name :string]
                            [address :ref :component]))
                  (schema address
                          (fields
                            [street :string]
                            [city :string]))]]
    (d/transact conn (generate-schema d/tempid dbschema))
    (println (d/basis-t (d/db conn)))

    (d/transact conn [{:db/id             (d/tempid :db.part/user)
                       :person/first-name "Ole"
                       :person/last-name  "Olsen"
                       :person/address    {:address/street "Gata 1"
                                           :address/city   "Oslo"}}])
    (println (d/basis-t (d/db conn)))

    (d/transact conn [{:db/id             (d/tempid :db.part/user)
                       :person/first-name "Lise"
                       :person/last-name  "Jensen"}])
    (println (d/basis-t (d/db conn)))

    (d/transact conn [[:db/retract 17592186045418 :person/first-name "Ole"]])
    (println (d/basis-t (d/db conn)))

    (d/transact conn [{:db/id             (d/tempid :db.part/user)
                       :person/first-name "Petter"
                       :person/last-name  "Arnesen"}])
    (println (d/basis-t (d/db conn)))

    (d/transact conn [[:db.fn/retractEntity 17592186045420]])
    (println (d/basis-t (d/db conn)))

    (models/get-updates
      (models/current-db)
      1000
      [17592186045418 17592186045420 17592186045423])))

#_(run)
