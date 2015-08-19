(ns cglossa.search.cwb.shared
  "Shared code for all types of corpora encoded with the IMS Open Corpus Workbench."
  (:require [clojure.string :as str]
            [me.raynes.fs :as fs]
            [me.raynes.conch :as conch]
            [cglossa.search.core :refer [run-queries transform-results]]))

(defn cwb-corpus-name [corpus queries]
  (let [uc-code (str/upper-case (:code corpus))]
    (if (:multilingual? corpus)
      ;; The CWB corpus we select before running our query will be the one named by the
      ;; code attribute of the corpus plus the name of the language of the first
      ;; submitted query row (e.g. RUN_EN).
      (str uc-code "_" (-> queries first :lang str/upper-case))
      uc-code)))

(defn cwb-query-name [corpus search-id]
  "Constructs a name for the saved query in CQP, e.g. MYCORPUS11."
  (str (str/upper-case (:code corpus))
       (last (str/split search-id #":"))))

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

(defn construct-query-commands [corpus queries named-query search-id cut]
  (let [query-str          (if (:multilingual? corpus)
                             (build-multilingual-query queries)
                             (build-monolingual-query queries))
        positions-filename (str (fs/tmpdir) "positions_" search-id)
        init-cmds          (if (:metadata-value-ids queries)
                             [(str "undump " named-query " < '" positions-filename \')
                              named-query]
                             [])]
    (conj init-cmds (str named-query " = " query-str " cut " cut))))

(defn run-cqp-commands [commands]
  (let [cmdfile   (str (fs/tmpdir) (fs/temp-name "cglossa-cqp-cmd"))
        commands* (->> commands
                       (map #(str % \;))
                       (str/join \newline))]
    (spit cmdfile commands*)
    (let [results (-> (conch/with-programs [cqp]
                                           (cqp "-c" "-f" cmdfile {:seq true}))
                      ;; Throw away the first line with the CQP version
                      rest)]
      (if (re-find #"PARSE ERROR|CQP Error" (first results))
        (throw (str "CQP error: " results))
        results))))
