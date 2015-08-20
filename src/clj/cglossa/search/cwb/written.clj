(ns cglossa.search.cwb.written
  "Support for written corpora encoded with the IMS Open Corpus Workbench."
  (:require [me.raynes.fs :as fs]
            [cglossa.db :as db]
            [cglossa.search.core :refer [run-queries transform-results]]
            [cglossa.search.cwb.shared :refer [cwb-query-name cwb-corpus-name run-cqp-commands
                                               construct-query-commands]]))

(defmethod run-queries :default [corpus search queries]
  (let [search-id   (db/stringify-rid search)
        named-query (cwb-query-name corpus search-id)
        commands    [(str "set DataDirectory \"" (fs/tmpdir) \")
                     (cwb-corpus-name corpus queries)
                     (construct-query-commands corpus queries named-query search-id 100)
                     (str "set Context 1 s")
                     "set LD \"{{\""
                     "set RD \"}}\""
                     (str "show +s_id")
                     "cat Last"]]
    (run-cqp-commands (flatten commands))))

(defmethod transform-results :default [_ results]
  (map (fn [r] {:text r}) results))
