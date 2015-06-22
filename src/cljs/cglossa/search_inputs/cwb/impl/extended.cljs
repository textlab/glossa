(ns cglossa.search-inputs.cwb.impl.extended
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

(defn- split-query [query]
  (let [terms (re-seq terms-regex query)]
    (if (str/blank? terms)
      ["[]"]
      terms)))

(defn- construct-query-terms [parts]
  (for [item parts]
    (condp re-matches (first item)
      interval (let [values (second item)
                     min    (some->> values
                                     (re-find #"(\d+),")
                                     last)
                     max    (some->> values
                                     (re-find #",(\d+)")
                                     last)]
                 [min max])
      attribute-value (let [attrs (str/split (last item) #"\s*&\s*")]
                        (reduce (fn [m attr]
                                  (let [[_ name val]
                                        (re-find #"\(?(\S+)\s*=\s*\"(\S+)\"" attr)]
                                    (case name
                                      ("word" "lemma" "phon")
                                      (cond-> (assoc m :word val)
                                              (= name "lemma") (assoc :lemma? true)
                                              (= name "phon") (assoc :phon? true)
                                              (re-find #"\.\+$" val) (assoc :start? true)
                                              (re-find #"^\.\+" val) (assoc :end? true))

                                      "pos"
                                      (assoc m :pos val)

                                      ;; default
                                      (update-in m [:features] assoc name val))))
                                {}
                                attrs))
      quoted-or-empty-term (.log js/console "quoted-or-empty")
      "hei")))

