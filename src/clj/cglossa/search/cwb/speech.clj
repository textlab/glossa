(ns cglossa.search.cwb.speech
  "Support for speech corpora encoded with the IMS Open Corpus Workbench."
  (:require [clojure.string :as str]
            [me.raynes.fs :as fs]
            [cglossa.db :as db]
            [cglossa.search.core :refer [run-queries transform-results]]
            [cglossa.search.cwb.shared :refer [cwb-query-name cwb-corpus-name
                                               construct-query-commands run-cqp-commands]]))

;; TODO: Fetch these from the definition of the tag set for the tagger that is being used
(def ^:private display-attrs [:lemma :phon :pos :gender :num :type :defn
                              :temp :pers :case :degr :descr :nlex :mood :voice])

(defmethod run-queries :cwb_speech [corpus search queries]
  (let [search-id   (db/stringify-rid search)
        named-query (cwb-query-name corpus search-id)
        commands    [(str "set DataDirectory \"" (fs/tmpdir) \")
                     (cwb-corpus-name corpus queries)
                     (construct-query-commands corpus queries named-query search-id 100
                                               :s-tag "sync_time")
                     (str "set Context 7 sync_time")
                     "set LD \"{{\""
                     "set RD \"}}\""
                     "show +sync_time +sync_end +who_name +who_line_key"
                     "cat Last"]]
    (run-cqp-commands corpus (flatten commands))))

(defn- fix-brace-positions [result]
  ;; If the matching word/phrase is at the beginning of the segment, CQP puts the braces
  ;; marking the start of the match before the starting segment tag
  ;; (e.g. {{<turn_endtime 38.26><turn_starttime 30.34>went/go/PAST>...). Probably a
  ;; bug in CQP? In any case we have to fix it by moving the braces to the
  ;; start of the segment text instead. Similarly if the match is at the end of a segment.
  (-> result
      (str/replace #"\{\{((?:<\S+?\s+?\S+?>\s*)+)"          ; Find start tags with attributes
                   "$1{{")                                  ; (i.e., not the match)
      (str/replace #"((?:</\S+?>\s*)+)\}\}"                 ; Find end tags
                   "}}$1")))

(defn- find-timestamps [result]
  (for [[segment start end] (re-seq #"<sync_time\s+([\d\.]+)><sync_end\s+([\d\.]+)>.*?</sync_time>"
                                    result)
        :let [num-speakers (count (re-seq #"<who_name" segment))]]
    ;; Repeat the start and end time for each speaker within the same segment
    [(repeat num-speakers start) (repeat num-speakers end)]))

(defn- build-annotation [index line speaker starttime endtime]
  (let [match? (re-find #"\{\{" line)
        line*  (str/replace line #"\{\{|\}\}" "")
        tokens (re-seq #"\s+" line*)]
    [index {:speaker  speaker
            :line     (into {} (map-indexed (fn [index token]
                                              (let [attr-values (str/split token #"/")]
                                                [index (zipmap (cons "word" display-attrs)
                                                               attr-values)]))
                                            tokens))
            :from     starttime
            :to       endtime
            :is_match match?}]))

(defn- create-media-object
  "Creates the data structure that is needed by jPlayer for a single search result."
  [overall-starttime overall-endtime starttimes endtimes lines speakers corpus line-key]
  (let [annotations         (into {} (map build-annotation
                                          (range) lines speakers
                                          starttimes endtimes))
        matching-line-index (first (keep-indexed #(when (re-find #"\{\{" %2) %1) lines))
        last-line-index     (dec (count lines))]
    {:title             ""
     :last_line         last-line-index
     :display_attribute "word"
     :corpus_id         (get corpus (keyword "@rid"))
     :mov               {:supplied "m4v"
                         :path     (str "media/" (:code corpus))
                         :line_key line-key
                         :start    overall-starttime
                         :stop     overall-endtime}
     :divs              {:annotation annotations}
     :start_at          matching-line-index
     :end_at            matching-line-index
     :min_start         0
     :max_end           last-line-index}))

(defmethod transform-results :cwb_speech [corpus results]
  (for [result results
        :let [result*           (fix-brace-positions result)
              [starttimes endtimes] (find-timestamps result*)
              overall-starttime (ffirst starttimes)
              overall-endtime   (last (last endtimes))
              speakers          (map second (re-seq #"<who_name\s+(.+?)>" result*))
              ;; All line keys within the same result should point to the same media file,
              ;; so just find the first one. Note that corpora are only marked with line
              ;; keys if they do in fact have media files, so line-key might be nil.
              line-key          (second (re-find #"<who_line_key\s+(\d+)>" result*))
              segments          (->> result*
                                     (re-seq #"<sync_end.+?>(.+?)</sync_end")
                                     (map second)
                                     ;; Remove line key attribute tags, since they would only
                                     ;; confuse the client code
                                     (map #(str/replace % #"</?who_line_key.*?>" "")))
              ;; We asked for a context of several segments to the left and right of the one
              ;; containing the matching word or phrase in order to be able to show them in the
              ;; media player display. However, only the segment with the match (marked by braces)
              ;; should be included in the search result shown in the result table.
              displayed-line    (first (filter (partial re-find #"\{\{.+\}\}") segments))]]
    (if-not line-key
      {:text displayed-line}
      (let [media-obj-lines (map second (re-seq (if line-key
                                                  #"<who_line_key.+?>(.*?)</who_line_key>"
                                                  #"<who_name.+?>(.*?)</who_name>")
                                                result*))]
        {:text      displayed-line
         :media-obj (create-media-object overall-starttime overall-endtime starttimes endtimes
                                         media-obj-lines speakers corpus line-key)
         :line-key  line-key}))))
