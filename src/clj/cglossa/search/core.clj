(ns cglossa.search.core
  (:require [cglossa.db :as db]))

(defmulti run-queries
  "Multimethod for actually running the received queries in a way that is
  appropriate for the search engine of the corpus in question."
  (fn [corpus _ _ _ _ _] (keyword (:search_engine corpus))))

(defmulti transform-results
  "Multimethod for transforming search results in a way that is
  appropriate for the search engine of the corpus in question."
  (fn [corpus _] (keyword (:search_engine corpus))))

(defn search [corpus-id queries step cut sort-by]
  (let [search  (db/run-sql "create vertex Search")
        corpus  (first (db/sql-query "select from #TARGET" {:target corpus-id}))
        results (run-queries corpus search queries step cut sort-by)]
    (-> search
        db/vertex->map
        (assoc :results (transform-results corpus results)))))
