(ns cglossa.search.cwb.speech
  "Support for speech corpora encoded with the IMS Open Corpus Workbench."
  (:require [clojure.string :as str]
            [me.raynes.fs :as fs]
            [cglossa.db :as db]
            [cglossa.search.core :refer [run-queries transform-results]]
            [cglossa.search.cwb.shared :refer [cwb-query-name cwb-corpus-name
                                               construct-query-commands run-cqp-commands]]))

(defmethod run-queries :cwb_speech [corpus search queries]
  (let [search-id   (db/stringify-rid search)
        named-query (cwb-query-name corpus search-id)
        commands    [(str "set DataDirectory \"" (fs/tmpdir) \")
                     (cwb-corpus-name corpus queries)
                     (construct-query-commands corpus queries named-query search-id 100)
                     (str "set Context 7 s")
                     "set LD \"{{\""
                     "set RD \"}}\""
                     "show +sync_time"
                     "cat Last"]]
    (run-cqp-commands (flatten commands))))

(defn- fix-brace-positions [result]
  ;; If the matching word/phrase is at the beginning of the segment, CQP puts the braces
  ;; marking the start of the match before the starting segment tag
  ;; (e.g. {{<turn_endtime 38.26><turn_starttime 30.34>went/go/PAST>...). Probably a
  ;; bug in CQP? In any case we have to fix it by moving the braces to the
  ;; start of the segment text instead. Similarly if the match is at the end of a segment.
  (-> result
      (str/replace #"\{\{((?:<\S+?\s+?\S+?>\s*)+)"          ; Find start tags with attributes
                   "\1{{")                                  ; (i.e., not the match)
      (str/replace #"((?:</\S+?>\s*)+)\}\}"                 ; Find end tags
                   "}}\1")))

(defn- find-timestamps [result]
  (for [[segment start end] (re-seq #"<sync_time\s+([\d\.]+)><sync_end\s+([\d\.]+)>.*?</sync_time>"
                                    result)
        num-speakers (count (re-seq #"<who_name" segment))]
    ;; Repeat the start and end time for each speaker within the same segment
    [(repeat num-speakers start) (repeat num-speakers end)]))

(defmethod transform-results :cwb_speech [corpus results]
  (for [result results
        :let [text              (fix-brace-positions result)
              [starttimes endtimes] (find-timestamps result)
              overall-starttime (ffirst starttimes)
              overall-endtime   (last (last endtimes))
              speakers          (map second (re-seq #"<who_name\s+(.+?)>" result))
              ;; All line keys within the same result should point to the same media file,
              ;; so just find the first one. Note that corpora are only marked with line
              ;; keys if they do in fact have media files, so line-key might be nil.
              line-key          (second (re-find #"<who_line_key\s+(\d+)>" result))
              lines             (map second (re-seq (if line-key
                                                      #"<who_line_key.+?>(.*?)</who_line_key>"
                                                      #"<who_name.+?>(.*?)</who_name>")
                                                    result))
              ;; We asked for a context of several units to the left and right of the unit
              ;; containing the matching word or phrase, but only the unit with the match (marked
              ;; by braces) should be included in the search result shown in the result table.
              displayed-line    (first (filter (partial re-find #"\{\{.+\}\}") lines))]]
    {:text text}))
