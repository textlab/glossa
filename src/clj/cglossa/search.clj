(ns cglossa.search
  (:require [cglossa.db :as db]
            [clojure.string :as str]))

(defn search [corpus-rid queries]
  (let [corpus (db/sql-query "select from #TARGET" {:target corpus-rid})]
    "hei"))