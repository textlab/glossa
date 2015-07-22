(ns cglossa.search
  (:require [cglossa.db :as db]
            [clojure.string :as str]
            [me.raynes.fs :as fs]
            [me.raynes.conch :as conch]))

(defn- cwb-corpus-name [corpus queries]
  (let [uc-code (str/upper-case (:code corpus))]
    (if (:multilingual? corpus)
      ;; The CWB corpus we select before running our query will be the one named by the
      ;; code attribute of the corpus plus the name of the language of the first
      ;; submitted query row (e.g. RUN_EN).
      (str uc-code "_" (-> queries first :lang str/upper-case))
      uc-code)))

(defn- build-monolingual-query [queries]
  ;; For monolingual queries, the query expressions should be joined together with '|' (i.e., "or")
  (let [queries* (map :query queries)]
    (if (> (count queries*) 1)
      (->> queries*
           (map #(str "(" % ")"))
           (str/join " | "))
      (first queries*))))

(defn- build-multilingual-query [queries]
  ;; TODO
  )

(defn- run-cqp-commands [commands]
  (let [cmdfile   (str (fs/tmpdir) (fs/temp-name "cglossa-cqp-cmd"))
        commands* (->> commands
                       (map #(str % \;))
                       (str/join \newline))]
    (spit cmdfile commands*)
    (let [results (-> (conch/with-programs [cqp]
                                           (cqp "-c" "-f" cmdfile {:seq true}))
                      ;; Throw away the first line with the CQP version
                      rest)]
      (fs/delete cmdfile)
      results)))

(defn search [corpus-rid queries]
  (let [search         (db/run-sql "create vertex Search")
        search-id      (db/stringify-rid search)
        corpus         (first (db/sql-query "select from #TARGET" {:target corpus-rid}))
        ;; name of saved query in CQP, e.g. MYCORPUS11
        named-query    (str (str/upper-case (:code corpus))
                            (last (str/split search-id #":")))
        query-str      (if (:multilingual? corpus)
                         (build-multilingual-query queries)
                         (build-monolingual-query queries))
        query-commands (if (:metadata-value-ids queries)
                         ""                                 ; TODO
                         (str named-query " = " query-str))
        commands       [(str "set DataDirectory \"" (fs/tmpdir) \")
                        (cwb-corpus-name corpus queries)
                        query-commands
                        (str "save " named-query)
                        "size Last"]
        num-hits       (run-cqp-commands commands)]
    (-> search
        db/vertex->map
        (assoc :num-hits num-hits))))