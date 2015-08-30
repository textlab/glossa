(ns cglossa.search.cwb.written
  "Support for written corpora encoded with the IMS Open Corpus Workbench."
  (:require [me.raynes.fs :as fs]
            [cglossa.db :as db]
            [cglossa.search.core :refer [run-queries get-results transform-results]]
            [cglossa.search.cwb.shared :refer [cwb-query-name cwb-corpus-name run-cqp-commands
                                               construct-query-commands]]
            [clojure.string :as str]))

(defmethod run-queries :default [corpus search queries step cut sort-by]
  (let [search-id   (:rid search)
        named-query (cwb-query-name corpus search-id)
        commands    [(str "set DataDirectory \"" (fs/tmpdir) \")
                     (cwb-corpus-name corpus queries)
                     (construct-query-commands corpus queries named-query search-id 100)
                     (when (> step 1)
                       (str "save " named-query))
                     (str "set Context 1 s")
                     "set LD \"{{\""
                     "set RD \"}}\""
                     "show +s_id"
                     (if (= step 1)
                       ;; When we do the first search, which has been cut to a single page of
                       ;; search results, we return all those results
                       "cat Last"
                       ;; When we are retrieving more results, we just tell the browser how
                       ;; many results we have found (so far)
                       "size Last")]]
    (run-cqp-commands corpus (flatten commands))))

(defmethod get-results :default [corpus search-id start end sort-by]
  (let [named-query (cwb-query-name corpus search-id)
        commands    [(str "set DataDirectory \"" (fs/tmpdir) \")
                     (str/upper-case (:code corpus))
                     (str "set Context 1 s")
                     "set LD \"{{\""
                     "set RD \"}}\""
                     "show +s_id"
                     (str "cat " named-query " " start " " end)]]
    (run-cqp-commands corpus (flatten commands))))

(defmethod transform-results :default [_ results]
  (map (fn [r] {:text r}) results))
