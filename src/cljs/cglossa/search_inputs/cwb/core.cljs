(ns cglossa.search-inputs.cwb.core
  (:require [clojure.string :as str]
            [reagent.core :as reagent]
            [goog.dom :as dom]
            [cglossa.search-inputs.cwb.shared :refer [on-key-down search!
                                                      remove-row-btn]]
            [cglossa.search-inputs.cwb.extended :as extended :refer [interval multiword-term]]))

(def ^:private headword-query-prefix "<headword>")
(def ^:private headword-query-suffix-more-words "[]{0,}")
(def ^:private headword-query-suffix-tag "</headword>")

(defn- ->headword-query [query]
  (str headword-query-prefix
       query
       headword-query-suffix-more-words
       headword-query-suffix-tag))

(defn- without-prefix [s prefix]
  (let [prefix-len (count prefix)]
    (if (= (subs s 0 prefix-len) prefix)
      (subs s prefix-len)
      s)))

(defn- without-suffix [s suffix]
  (let [suffix-start (- (count s) (count suffix))]
    (if (= (subs s suffix-start) suffix)
      (subs s 0 suffix-start)
      s)))

(defn- ->non-headword-query [query]
  (-> query
      (without-suffix headword-query-suffix-tag)
      (without-suffix headword-query-suffix-more-words)
      (without-prefix headword-query-prefix)))

(defn- phrase->cqp [phrase phonetic?]
  (let [attr       (if phonetic? "phon" "word")
        chinese-ch "[\u4E00-\u9FFF\u3400-\u4DFF\uF900-\uFAFF]"
        ; Surround every Chinese character by space when constructing a cqp query,
        ; to treat it as if it was an individual word:
        p1         (str/replace phrase
                                (re-pattern (str "(" chinese-ch ")"))
                                " $1 ")
        p2         (as-> (str/split p1 #"\s") $
                         (map #(if (= % "")
                                ""
                                (str "[" attr "=\"" % "\" %c]"))
                              $)
                         (str/join " " $)
                         (str/replace $
                                      (re-pattern (str "\\s(\\[\\w+=\""
                                                       chinese-ch
                                                       "\"(?:\\s+%c)?\\])\\s"))
                                      "$1")
                         ;; NOTE: In JavaScript, "han ".split(/\s/) yields the array
                         ;; ["han", " "], but in ClojureScript (str/split "han " #"\s")
                         ;; only yields ["han"]. Hence, in the CLJS version we need to
                         ;; add the extra element if the query ends in a space.
                         (if (= \space (last (seq p1))) (str $ " ") $))]
    (if (str/blank? p2)
      (str "[" attr "=\".*\" %c]")
      p2)))

;;;;;;;;;;;;;;;;;
; Event handlers
;;;;;;;;;;;;;;;;;

(defn- on-phonetic-changed [event query-cursor]
  (let [q        (:query @query-cursor)
        checked? (.-target.checked event)
        query    (if checked?
                   (if (str/blank? q)
                     "[phon=\".*\" %c]"
                     (str/replace q "word=" "phon="))
                   (str/replace q "phon=" "word="))]
    (swap! query-cursor assoc :query query)))

(defn- on-headword-search-changed [event query-cursor]
  (swap! query-cursor assoc :headword-search (.-target.checked event)))

;;;;;;;;;;;;;
; Components
;;;;;;;;;;;;;

(defn- search-button [multilingual?]
  [:button.btn.btn-success {:style    {:marginLeft (if multilingual? 80 40)}
                            :on-click search!} "Search"])

(defn- add-language-button []
  [:button.btn {:style {:marginLeft 20} :on-click #()} "Add language"])

(defn- add-phrase-button []
  [:button.btn.btn-default.add-phrase-btn {:on-click #()} "Or..."])

(defn- language-select [languages selected-language]
  [:select {:value selected-language}
   (for [language languages]
     [:option {:key (:value language) :value (:value language)} (:text language)])])

(defn- headword-search-checkbox [query-cursor]
  [:label {:style {:margin-left 20}}
   [:input {:type      "checkbox"
            :value     "1"
            :checked   (:headword-search @query-cursor)
            :on-change #(on-headword-search-changed % query-cursor)
            :id        "headword_search"
            :name      "headword_search"} " Headword search"]])

(defn- focus-text-input [c]
  (.focus (dom/findNode (reagent/dom-node c) #(= "text" (.-type %)))))

(defn- single-input-view
  "HTML that is shared by the search views that only show a single text input,
  i.e., the simple and CQP views."
  [corpus query-cursor displayed-query show-remove-row-btn? show-checkboxes?
   remove-row-handler on-text-changed]
  (let [query     (:query @query-cursor)
        phonetic? (not= -1 (.indexOf query "phon="))]
    [:form {:style {:display "table" :margin "10px 0px 20px -30px"}}
     [:div {:style {:display "table-row" :margin-bottom 10}}
      [:div {:style {:display "table-cell"}}
       [remove-row-btn show-remove-row-btn? remove-row-handler]]
      [:div.form-group {:style {:display "table-cell"}}
       [:input.form-control.col-md-12 {:style       {:width 500}
                                       :type        "text"
                                       :value       displayed-query
                                       :on-change   #(on-text-changed % query-cursor phonetic?)
                                       :on-key-down #(on-key-down % query-cursor)}]]]
     (when show-checkboxes?
       [:div {:style {:display "table-row"}}
        [:div {:style {:display "table-cell"}}]
        [:div.checkbox {:style {:display "table-cell"}}
         (when (:has-phonetic corpus)
           [:label
            [:input {:name      "phonetic"
                     :type      "checkbox"
                     :checked   phonetic?
                     :on-change #(on-phonetic-changed % query-cursor)}] " Phonetic form"])
         (when (:has-headword-search corpus)
           [headword-search-checkbox query-cursor])]])]))

(defn- simple
  "Simple search view component"
  [corpus query-cursor show-remove-row-btn? remove-row-handler]
  (let [query           (:query @query-cursor)
        displayed-query (-> query
                            (->non-headword-query)
                            (str/replace #"\[\(?\w+=\"(.*?)\"(?:\s+%c)?\)?\]" "$1")
                            (str/replace #"\"([^\s=]+)\"" "$1")
                            (str/replace #"\s*\[\]\s*" " .* ")
                            (str/replace #"^\.\*$" ""))
        on-text-changed (fn [event query-cursor phonetic?]
                          (let [value (.-target.value event)
                                query (if (= value "") "" (phrase->cqp value phonetic?))]
                            (swap! query-cursor assoc :query query)))]
    [single-input-view corpus query-cursor displayed-query show-remove-row-btn?
     true remove-row-handler on-text-changed]))

(defn- extended
  "Search view component with text inputs, checkboxes and menus
  for easily building complex and grammatically specified queries."
  [corpus query-cursor show-remove-row-btn? remove-row-handler]
  (let [parts           (extended/split-query (:query @query-cursor))
        terms           (extended/construct-query-terms parts)
        last-term-index (dec (count terms))]
    (.log js/console (str terms))
    [:div.multiword-container
     [:form.form-inline.multiword-search-form {:style {:margin-left -30}}
      [:div {:style {:display "table"}}
       [:div {:style {:display "table-row"}}
        (map-indexed (fn [index term]
                       (let [first?                (zero? index)
                             last?                 (= index last-term-index)
                             ;; Show buttons to remove terms if there are more than one term
                             show-remove-term-btn? (pos? last-term-index)
                             has-phonetic?         (:has-phonetic corpus)
                             remove-term-handler   #()]
                         (list (when-not first?
                                 [interval query-cursor term])
                               [multiword-term query-cursor term first? last? has-phonetic?
                                show-remove-row-btn? remove-row-handler
                                show-remove-term-btn? remove-term-handler])))
                     terms)]
       (when (:has-headword-search corpus)
         [headword-search-checkbox query-cursor])]]]))

(defn- cqp
  "CQP query view component"
  [corpus query-cursor show-remove-row-btn? remove-query-handler]
  (let [displayed-query (:query @query-cursor)
        on-text-changed (fn [event query-cursor _]
                          (let [value      (.-target.value event)
                                query      (->non-headword-query value)
                                hw-search? (= (->headword-query query) value)]
                            (swap! query-cursor assoc :query query :headword-search hw-search?)))]
    [single-input-view corpus query-cursor displayed-query show-remove-row-btn?
     false remove-query-handler on-text-changed]))

(defn search-inputs
  "Component that lets the user select a search view (simple, extended
  or CQP query view) and displays it."
  [{:keys [search-view search-queries]} {:keys [corpus]}]
  (reagent/create-class
    {:component-did-mount
     focus-text-input

     :reagent-render
     (fn [{:keys [search-view search-queries]} {:keys [corpus]}]
       (let [view          (case @search-view
                             :extended extended
                             :cqp cqp
                             simple)
             languages     (:langs @corpus)
             multilingual? (> (count languages) 1)
             set-view      (fn [view e] (reset! search-view view) (.preventDefault e))
             query-get-set (fn
                             ([k] (get-in @search-queries k))
                             ([k v] (let [query (as-> (:query v) $
                                                      (if (get-in @search-queries
                                                                  [k :headword-search])
                                                        (->headword-query $)
                                                        (->non-headword-query $))
                                                      ;; Simplify the query (".*" is used in the
                                                      ;; simplified search instead of [])
                                                      (str/replace $
                                                                   #"\[\(?word=\"\.\*\"(?:\s+%c)?\)?\]"
                                                                   "[]")
                                                      (str/replace $ #"^\s*\[\]\s*$" ""))]
                                      (swap! search-queries assoc-in [(first k) :query] query)
                                      ;; TODO: Handle state.maxHits and state.lastSelectedMaxHits
                                      )))]
         [:span
          [:div.row.search-input-links
           [:div.col-md-12
            (if (= view simple)
              [:b "Simple"]
              [:a {:href     ""
                   :title    "Simple search box"
                   :on-click #(set-view :simple %)}
               "Simple"])
            " | "
            (if (= view extended)
              [:b "Extended"]
              [:a {:href     ""
                   :title    "Search for grammatical categories etc."
                   :on-click #(set-view :extended %)}
               "Extended"])
            " | "
            (if (= view cqp)
              [:b "CQP query"]
              [:a {:href     ""
                   :title    "CQP expressions"
                   :on-click #(set-view :cqp %)}
               "CQP query"])
            [search-button multilingual?]
            (when multilingual? [add-language-button])]]

          ; Now create a cursor into the search-queries ratom for each search expression
          ; and display a row of search inputs for each of them. The doall call is needed
          ; because ratoms cannot be derefed inside lazy seqs.
          (let [nqueries             (count @search-queries)
                show-remove-row-btn? (> nqueries 1)
                remove-query         (fn [i] (swap! search-queries
                                                    #(vec (concat (subvec % 0 i)
                                                                  (subvec % (inc i))))))]
            (doall (for [index (range nqueries)]
                     (let [query-cursor       (reagent/cursor query-get-set [index])
                           selected-language  (-> @query-cursor :query :lang)
                           remove-row-handler (partial remove-query index)]
                       [:div.row
                        [:div.col-md-12
                         (when multilingual? [language-select languages selected-language])
                         ^{:key index} [view @corpus query-cursor show-remove-row-btn?
                                        remove-row-handler]]]))))
          (when-not multilingual? [add-phrase-button])]))}))
