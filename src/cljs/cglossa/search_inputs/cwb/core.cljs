(ns cglossa.search-inputs.cwb.core
  (:require [clojure.string :as str]
            [reagent.core :as reagent]
            [goog.dom :as dom]
            [cglossa.search-inputs.cwb.shared :refer [on-key-down search!
                                                      remove-row-btn]]
            [cglossa.search-inputs.cwb.extended :as ext :refer [interval multiword-term]]))

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

(defn- focus-text-input [c]
  (.focus (dom/findNode (reagent/dom-node c) #(= "text" (.-type %)))))

(defn- wrapped-query-changed [queries index query]
  "Takes a changed query, performs some cleanup on it, and swaps it into
  the appropriate position in the vector of queries that constitute the
  current search."
  (let [query* (as-> (:query query) $
                     (if (get-in @queries [index :headword-search])
                       (->headword-query $)
                       (->non-headword-query $))
                     ;; Simplify the query (".*" is used in the
                     ;; simplified search instead of [])
                     (str/replace $ #"\[\(?word=\"\.\*\"(?:\s+%c)?\)?\]" "[]")
                     (str/replace $ #"^\s*\[\]\s*$" ""))]
    (swap! queries assoc-in [index :query] query*)
    ;; TODO: Handle state.maxHits and state.lastSelectedMaxHits
    ))

;;;;;;;;;;;;;;;;;
; Event handlers
;;;;;;;;;;;;;;;;;

(defn- on-phonetic-changed [event wrapped-query]
  (let [q        (:query @wrapped-query)
        checked? (.-target.checked event)
        query    (if checked?
                   (if (str/blank? q)
                     "[phon=\".*\" %c]"
                     (str/replace q "word=" "phon="))
                   (str/replace q "phon=" "word="))]
    (swap! wrapped-query assoc :query query)))

(defn- on-headword-search-changed [event wrapped-query]
  (swap! wrapped-query assoc :headword-search (.-target.checked event)))

;;;;;;;;;;;;;
; Components
;;;;;;;;;;;;;

(defn- search-button [margin-left]
  [:button.btn.btn-success {:style    {:marginLeft margin-left}
                            :on-click search!} "Search"])

(defn- add-language-button []
  [:button.btn {:style {:marginLeft 20} :on-click #()} "Add language"])

(defn- add-phrase-button []
  [:button.btn.btn-default.add-phrase-btn {:on-click #()} "Or..."])

(defn- language-select [languages selected-language]
  [:select {:value selected-language}
   (for [language languages]
     [:option {:key (:value language) :value (:value language)} (:text language)])])

(defn- headword-search-checkbox [wrapped-query]
  [:label {:style {:margin-left 20}}
   [:input {:type      "checkbox"
            :value     "1"
            :checked   (:headword-search @wrapped-query)
            :on-change #(on-headword-search-changed % wrapped-query)
            :id        "headword_search"
            :name      "headword_search"} " Headword search"]])

(defn- single-input-view
  "HTML that is shared by the search views that only show a single text input,
  i.e., the simple and CQP views."
  [corpus wrapped-query displayed-query show-remove-row-btn? show-checkboxes?
   remove-row-handler on-text-changed]
  (let [query     (:query @wrapped-query)
        phonetic? (not= -1 (.indexOf query "phon="))]
    [:form {:style {:display "table" :margin "10px 0px 15px -30px"}}
     [:div {:style {:display "table-row" :margin-bottom 10}}
      [:div.table-cell.remove-row-btn-container
       [remove-row-btn show-remove-row-btn? remove-row-handler]]
      [:div.form-group {:style {:display "table-cell"}}
       [:input.form-control.col-md-12 {:style       {:width 500}
                                       :type        "text"
                                       :value       displayed-query
                                       :on-change   #(on-text-changed % wrapped-query phonetic?)
                                       :on-key-down #(on-key-down % wrapped-query)}]]]
     (when show-checkboxes?
       [:div {:style {:display "table-row"}}
        [:div {:style {:display "table-cell"}}]
        [:div.checkbox {:style {:display "table-cell"}}
         (when (:has-phonetic corpus)
           [:label {:style {:margin-top 7}}
            [:input {:name      "phonetic"
                     :type      "checkbox"
                     :checked   phonetic?
                     :on-change #(on-phonetic-changed % wrapped-query)}] " Phonetic form"])
         (when (:has-headword-search corpus)
           [headword-search-checkbox wrapped-query])]])]))

;;; The three different CWB interfaces: simple, extended and cqp

(defn- simple
  "Simple search view component"
  [corpus wrapped-query show-remove-row-btn? remove-row-handler]
  (let [query           (:query @wrapped-query)
        displayed-query (-> query
                            (->non-headword-query)
                            (str/replace #"\[\(?\w+=\"(.*?)\"(?:\s+%c)?\)?\]" "$1")
                            (str/replace #"\"([^\s=]+)\"" "$1")
                            (str/replace #"\s*\[\]\s*" " .* ")
                            (str/replace #"^\.\*$" ""))
        on-text-changed (fn [event wrapped-query phonetic?]
                          (let [value (.-target.value event)
                                query (if (= value "") "" (phrase->cqp value phonetic?))]
                            (swap! wrapped-query assoc :query query)))]
    [single-input-view corpus wrapped-query displayed-query show-remove-row-btn?
     true remove-row-handler on-text-changed]))

(defn- extended
  "Search view component with text inputs, checkboxes and menus
  for easily building complex and grammatically specified queries."
  [corpus wrapped-query show-remove-row-btn? remove-row-handler]
  (let [parts           (ext/split-query (:query @wrapped-query))
        terms           (ext/construct-query-terms parts)
        last-term-index (dec (count terms))]
    (.log js/console (str terms))
    [:div.multiword-container
     [:form.form-inline.multiword-search-form {:style {:margin-left -30}}
      [:div {:style {:display "table"}}
       [:div {:style {:display "table-row"}}
        (map-indexed (fn [index term]
                       (let [first?                (zero? index)
                             last?                 (= index last-term-index)
                             ;; Show buttons to remove terms if there is more than one term
                             show-remove-term-btn? (pos? last-term-index)
                             has-phonetic?         (:has-phonetic corpus)
                             remove-term-handler   #()]
                         (list (when-not first?
                                 ^{:key (str "interval" index)}
                                 [interval wrapped-query term])
                               ^{:key (str "term" index)}
                               [multiword-term wrapped-query term first? last? has-phonetic?
                                show-remove-row-btn? remove-row-handler
                                show-remove-term-btn? remove-term-handler])))
                     terms)]
       (when (:has-headword-search corpus)
         [headword-search-checkbox wrapped-query])]]]))

(defn- cqp
  "CQP query view component"
  [corpus wrapped-query show-remove-row-btn? remove-query-handler]
  (let [displayed-query (:query @wrapped-query)
        on-text-changed (fn [event wrapped-query _]
                          (let [value      (.-target.value event)
                                query      (->non-headword-query value)
                                hw-search? (= (->headword-query query) value)]
                            (swap! wrapped-query assoc :query query :headword-search hw-search?)))]
    [single-input-view corpus wrapped-query displayed-query show-remove-row-btn?
     false remove-query-handler on-text-changed]))

(defn search-inputs
  "Component that lets the user select a search view (simple, extended
  or CQP query view) and displays it."
  [{:keys [search-view search-queries]} {:keys [corpus]}]
  (reagent/create-class
    {:display-name
     "search-inputs"

     :component-did-mount
     focus-text-input

     :reagent-render
     (fn [{:keys [search-view search-queries]} {:keys [corpus]}]
       (let [view          (case @search-view
                             :extended extended
                             :cqp cqp
                             simple)
             languages     (:langs @corpus)
             multilingual? (> (count languages) 1)
             set-view      (fn [view e] (reset! search-view view) (.preventDefault e))]
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
            [search-button (if (= @search-view :extended) 75 233)]
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
                     ;; Use wrap rather than cursor to send individual queries down to
                     ;; child components (and in the extended view, we do the same for
                     ;; individual terms). When a query (or query term) changes, the wrap
                     ;; callbacks are called all the way up to the one setting the top-level
                     ;; search-queries ratom, and all query views (potentially) re-render.
                     ;;
                     ;; By using cursors we could have restricted re-rendering to smaller
                     ;; sub-views, but we need to do some processing of the query (such as
                     ;; changing " .* " to []) before updating it in the search-queries ratom.
                     ;; We could do this with a getter/setter-style cursor, but then we would
                     ;; have to update the search-queries ratom anyway, causing the same potential
                     ;; re-rendering of all query views.
                     ;;
                     ;; Probably the most efficient approach would be to use a standard cursor
                     ;; (which only re-renders the view that derefs it) and explicitly call the
                     ;; query processing function before updating the cursor, but then we would
                     ;; have to make sure to do that every time we change a query...
                     (let [wrapped-query      (reagent/wrap
                                                (nth @search-queries index)
                                                wrapped-query-changed search-queries index)
                           selected-language  (-> @wrapped-query :query :lang)
                           remove-row-handler (partial remove-query index)]
                       ^{:key index}
                       [:div.row
                        [:div.col-md-12
                         (when multilingual?
                           [language-select languages selected-language])
                         [view @corpus wrapped-query show-remove-row-btn? remove-row-handler]]]))))
          (when-not multilingual? [add-phrase-button])]))}))
