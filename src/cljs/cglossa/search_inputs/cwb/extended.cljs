(ns cglossa.search-inputs.cwb.extended
  "Implementation of search view component with text inputs, checkboxes
  and menus for easily building complex and grammatically specified queries."
  (:require [clojure.string :as str]
            [cglossa.search-inputs.cwb.shared :refer [on-key-down remove-row-btn]]))

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
              (= name "phon") (assoc :phonetic? true)
              (re-find #"\.\+$" val) (assoc :start? true)
              (re-find #"^\.\+" val) (assoc :end? true))

      "pos"
      (assoc term :pos val)

      ;; default
      (assoc-in term [:features name] val))))


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

(defn- construct-cqp-query [terms]
  (let [parts (for [{:keys [interval word lemma? phonetic? start? end? features]} terms]
                (let [attr   (cond
                               lemma? "lemma"
                               phonetic? "phon"
                               :else "word")
                      form   (if (empty? word)
                               ".*"
                               (cond-> word
                                       start? (str word ".+")
                                       end? (str ".+" word)))
                      main   (str "(" attr "=\"" form "\" %c)")
                      feats  (for [[name value] features]
                               (str name "=\"" value "\""))
                      [min max] interval
                      interv (if (or min max)
                               (str "[]{" (or min 0) "," (or max "") "} ")
                               "")]
                  (str interv "[" (str/join " & " (cons main feats)) "]")))]
    (str/join \space parts)))

(defn wrapped-term-changed [wrapped-query terms index term]
  (swap! wrapped-query assoc :query (construct-cqp-query (assoc terms index term))))

(defn- interval-input [wrapped-query wrapped-term index]
  [:input.form-control.interval {:type        "text"
                                 :value       (get-in @wrapped-term [:interval index])
                                 :on-change   #(swap! wrapped-term
                                                      assoc-in [:interval index] (.-target.value %))
                                 :on-key-down #(on-key-down % wrapped-query)}])

(defn interval [wrapped-query wrapped-term]
  [:div.interval.table-cell
   [interval-input wrapped-query wrapped-term 0] "min"
   [:br]
   [interval-input wrapped-query wrapped-term 1] "max"])

(defn multiword-term [wrapped-query wrapped-term first? last? has-phonetic?
                      show-remove-row-btn? remove-row-handler
                      show-remove-term-btn? remove-term-handler]
  (let [term-val @wrapped-term]
    [:div.table-cell
     [:div
      [:div.multiword-term
       [:div.control-group
        [:div {:style {:display "table"}}
         [:div.dropdown.table-row
          (when first?
            [:div.table-cell.remove-row-btn-container
             [remove-row-btn show-remove-row-btn? remove-row-handler]])
          [:div.table-cell
           [:div.input-group
            [:span.input-group-addon.dropdown-toggle {:data-toggle "dropdown"
                                                      :style       {:cursor "pointer"}}
             [:span.glyphicon.glyphicon-menu-hamburger]]
            [:input.form-control.multiword-field {:ref           "searchfield"
                                                  :type          "text"
                                                  :default-value (str/replace (:word term-val)
                                                                              #"^\.\*$"
                                                                              "")
                                                  ;:on-change     #(on-text-changed)
                                                  :on-key-down   #(on-key-down % wrapped-query)}]
            (when show-remove-term-btn?
              [:span.input-group-addon {:title " Remove word "
                                        :style {:cursor "pointer"}
                                        ;:on-click #(on-remove-term)
                                        }
               [:span.glyphicon.glyphicon-minus]])
            (when last?
              [:div.add-search-word
               [:button.btn.btn-info.btn-sm {:data-add-term-button ""
                                             :title                "Add search word"
                                             ;:on-click             #(on-add-term)
                                             }
                [:span.glyphicon.glyphicon-plus]]])]]]
         [:div.table-row
          (when first?
            [:div.table-cell])
          [:div.table-cell
           [:div.word-checkboxes
            [:label.checkbox-inline
             [:input {:type    "checkbox"
                      :checked (:lemma? term-val)
                      ;:on-change #(on-lemma?-changed)
                      }] "Lemma"]
            [:label.checkbox-inline
             [:input {:type    "checkbox"
                      :title   "Start of word"
                      :checked (:start? term-val)
                      ;:on-change #(on-start?-changed)
                      }] "Start"]
            [:label.checkbox-inline
             [:input {:type    "checkbox"
                      :title   "End of word"
                      :checked (:end? term-val)
                      ;:on-change #(on-end?-changed)
                      }] "End"]]
           (when has-phonetic?
             [:div
              [:label.checkbox-inline
               [:input {:type    "checkbox"
                        :checked (:phonetic? term-val)
                        ;:on-change #(on-phonetic?-changed)
                        }] "Phonetic form"]])]]
         [:div.table-row
          (when first?
            [:div.table-cell])
          [:div.tag-list.table-cell {:ref "taglist"}
           [:div.tags]]]]]]]]))
