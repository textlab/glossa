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

(def interval-rx #"\[\]\{(.+?)\}")
;; Treat quoted strings separately; they may contain right brackets
(def attribute-value-rx #"\[\(?([^\"]+?(?:\"[^\"]*\"[^\]\"]*?)*?)(?:\s+%c)?\)?\]")
(def quoted-or-empty-term-rx #"\".*?\"|\[\]")
(def terms-rx (combine-regexes [interval-rx quoted-or-empty-term-rx attribute-value-rx]))

(defn split-query [query]
  (let [terms (re-seq terms-rx query)]
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
  ;; them as the value of the :interval key in the map representing the following
  ;; query term.
  (let [interval (atom [nil nil])]
    (reduce (fn [terms part]
              (condp re-matches (first part)
                interval-rx (let [values (second part)
                               min    (some->> values
                                               (re-find #"(\d+),")
                                               last)
                               max    (some->> values
                                               (re-find #",(\d+)")
                                               last)]
                           (reset! interval [min max])
                           terms)
                attribute-value-rx (let [attrs (str/split (last part) #"\s*&\s*")
                                      term  (as-> {} $
                                                  (reduce process-attr $ attrs)
                                                  (assoc $ :interval @interval))]
                                  (reset! interval [nil nil])
                                  (conj terms term))
                quoted-or-empty-term-rx (.log js/console "quoted-or-empty")
                "hei"))
            []
            parts)))

(defn multiword-term
  [query-cursor term first? last? has-phonetic?
   show-remove-row-btn? remove-row-handler
   show-remove-term-btn? remove-term-handler
   on-key-down]
  [:div {:style {:display "table-cell"}}
   [:div {:style {:display "table-cell"}}
    [:div {:style {:display "table"}}
     [:div.multiword-term
      [:div.control-group
       [:div {:style {:display "table-row"}}
        (when-not first?
          [:div.interval
           [:h6 "Interval"]
           [:input.interval {:type        "text"
                             :value       (first (:maxmin term))
                             ;:on-change   #(on-min-changed)
                             :on-key-down #(on-key-down % query-cursor)}] "min"
           [:br]
           [:input.interval {:type        "text"
                             :value       (last (:maxmin term))
                             ;:on-change   #(on-max-changed)
                             :on-key-down #(on-key-down % query-cursor)}] "max"])
        [:div.input-prepend.input-append.word
         [:div.dropdown
          (when (and first? show-remove-row-btn?)
            [:button.btn.btn-default.btn-xs {:type     "button"
                                             :title    "Remove row"
                                             :on-click #(remove-row-handler)
                                             :style    {:margin-right 5
                                                        :margin-top   -25
                                                        :visibility   (if show-remove-row-btn?
                                                                        "visible"
                                                                        "hidden")}}
             [:span.glyphicon.glyphicon-remove]])
          [:span.add-on.dropdown-toggle {:data-toggle "dropdown"
                                         :style       {:cursor "pointer"}}
           [:i.icon-align-justify]]
          [:input.searchfield.multiword-field.removable {:ref           "searchfield"
                                                         :type          "text"
                                                         :default-value (str/replace (:word term)
                                                                                     #"^\.\*$"
                                                                                     "")
                                                         ;:on-change     #(on-text-changed)
                                                         :on-key-down   #(on-key-down % query-cursor)}]
          (if show-remove-term-btn?
            [:span.add-on {:title " Remove word "
                           :style {:cursor "pointer"}
                           ;:on-click #(on-remove-term)
                           }
             [:i.icon-minus]])
          (when last?
            [:div.add-search-word
             [:button.btn.btn-sm {:data-add-term-button ""
                                  :title                "Add search word"
                                  ;:on-click             #(on-add-term)
                                  }
              [:i.icon-plus]]])
          [:div {:style {:display "table-row"}}
           (when-not first?
             [:div.interval-filler {:style {:display "table-cell"}}])
           [:div.word-checkboxes
            [:label.checkbox
             [:input {:type    "checkbox"
                      :checked (:lemma? term)
                      ;:on-change #(on-lemma?-changed)
                      }] "Lemma"]
            [:label.checkbox
             [:input {:type    "checkbox"
                      :title   "Start of word"
                      :checked (:start? term)
                      ;:on-change #(on-start?-changed)
                      }] "Start"]
            [:label.checkbox
             [:input {:type    "checkbox"
                      :title   "End of wordd"
                      :checked (:end? term)
                      ;:on-change #(on-end?-changed)
                      }] "End"]
            [:div {:style {:display "table-cell"}}]]
           (when has-phonetic?
             [:div
              [:label.checkbox
               [:input {:type    "checkbox"
                        :checked (:phonetic? term)
                        ;:on-change #(on-phonetic?-changed)
                        }] "Phonetic form"]])]
          [:div {:style {:display "table-row"}}
           (when-not first?
             [:div.interval-filler {:style {:display "table-cell"}}])
           [:div.tag-list {:ref "taglist"}
            [:div.tags]]]]]]]]]]])
