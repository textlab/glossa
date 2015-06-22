(ns cglossa.search-inputs.cwb.impl.extended
  "Implementation of search view component with text inputs, checkboxes
  and menus for easily building complex and grammatically specified queries."
  (:require [clojure.string :as str]))

(defn- combine-regexes [regexes]
  "Since there is no way to concatenate regexes directly, we convert
  them to strings, remove the initial and final slash from each one,
  concatenate the resulting strings with a pipe symbol, and finally
  convert the concatenated string back to a single regex."
  (->> regexes
       (map str)
       (map (partial re-matches #"/(.+)/"))
       (map last)
       (str/join \|)
       re-pattern))

(def interval #"\[\]\{(.+?)\}")
;; Treat quoted strings separately; they may contain right brackets
(def attribute-value #"\[\(?([^\"]+?(?:\"[^\"]*\"[^\]\"]*?)*?)(?:\s+%c)?\)?\]")
(def quoted-or-empty-term #"\".*?\"|\[\]")
(def terms-regex (combine-regexes [interval quoted-or-empty-term attribute-value]))

(defn- multiword-term [term]
  )

(defn split-query [query]
  (let [terms (re-seq terms-regex query)]
    (if (str/blank? terms)
      ["[]"]
      terms)))

(defn- process-attr [term attr]
  (let [[_ name val] (re-find #"\(?(\S+)\s*=\s*\"(\S+)\"" attr)]
    (case name
      ("word" "lemma" "phon")
      (cond-> (assoc term :word (-> val
                                    (str/replace #"^(?:\.\+)?(.+?)" "$1")
                                    (str/replace #"(.+?)(?:\.\+)?$" "$1")))
              (= name "lemma") (assoc :lemma? true)
              (= name "phon") (assoc :phon? true)
              (re-find #"\.\+$" val) (assoc :start? true)
              (re-find #"^\.\+" val) (assoc :end? true))

      "pos"
      (assoc term :pos val)

      ;; default
      (update-in term [:features] assoc name val))))


(defn construct-query-terms [parts]
  ;; Use an atom to keep track of interval specifications so that we can set
  ;; them as the value of the :minmax key in the map representing the following
  ;; query term.
  (let [minmax (atom [nil nil])]
    (reduce (fn [terms part]
              (condp re-matches (first part)
                interval (let [values (second part)
                               min    (some->> values
                                               (re-find #"(\d+),")
                                               last)
                               max    (some->> values
                                               (re-find #",(\d+)")
                                               last)]
                           (reset! minmax [min max])
                           terms)
                attribute-value (let [attrs (str/split (last part) #"\s*&\s*")
                                      term  (as-> {} $
                                                  (reduce process-attr $ attrs)
                                                  (assoc $ :minmax @minmax))]
                                  (reset! minmax [nil nil])
                                  (conj terms term))
                quoted-or-empty-term (.log js/console "quoted-or-empty")
                "hei"))
            []
            parts)))
