(ns cglossa.search.core
  (:require [cglossa.db :as db]))

(defmulti run-queries
  "Multimethod for actually running the received queries in a way that is
  appropriate for the search engine of the corpus in question. The default
  search engine is CWB, and hence the :default case is implemented in
  cglossa.search.cwb."
  (fn [corpus _ _]
    (:search_engine corpus)))

(defn search [corpus-id queries]
  (let [search      (db/run-sql "create vertex Search")
        corpus      (first (db/sql-query "select from #TARGET" {:target corpus-id}))]
    (run-queries corpus search queries)))
