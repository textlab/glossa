(ns cglossa.search-views.cwb.core
  (:require [clojure.string :as str]
            [reagent.core :as r]
            [goog.dom :as dom]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.search-views.shared :refer [search-inputs]]
            [cglossa.search-views.cwb.shared :refer [headword-search-checkbox
                                                     on-key-down search!
                                                     remove-row-btn]]
            [cglossa.search-views.cwb.extended :refer [extended]]))

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
  ;; Use (aget % "type") instead of (.-type %) simply because the latter makes the syntax
  ;; checker in Cursive Clojure go bananas for some reason...
  (.focus (dom/findNode (r/dom-node c) #(= "text" (aget % "type")))))

(defn- wrapped-query-changed [queries index query-ids query]
  "Takes a changed query, performs some cleanup on it, and swaps it into
  the appropriate position in the vector of queries that constitutes the
  current search. If the query is nil, removes it from the vector instead."
  (if (nil? query)
    (do
      (swap! query-ids #(into (subvec % 0 index)
                              (subvec % (inc index))))
      (swap! queries #(into (subvec % 0 index)
                            (subvec % (inc index)))))
    (let [query* (as-> (:query query) $
                       (if (:headword-search query)
                         (->headword-query $)
                         (->non-headword-query $))
                       ;; Simplify the query (".*" is used in the simple search instead of [])
                       (str/replace $ #"\[\(?word=\"\.\*\"(?:\s+%c)?\)?\]" "[]")
                       (str/replace $ #"^\s*\[\]\s*$" ""))]
      (swap! queries assoc-in [index :query] query*)
      ;; TODO: Handle state.maxHits and state.lastSelectedMaxHits
      )))

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

;;;;;;;;;;;;;
; Components
;;;;;;;;;;;;;

(defn- search-button [a m margin-left]
  [b/button {:bs-style "success"
             :style    {:margin-left margin-left}
             :on-click #(search! a m)} "Search"])

(defn- add-language-button []
  [b/button {:style {:marginLeft 20} :on-click #()} "Add language"])

(defn- add-phrase-button [view]
  [b/button {:bs-size  "small"
             :style    {:margin-top (if (= view extended) -15 0)}
             :on-click #()} "Or..."])

(defn- language-select [languages selected-language]
  [:select {:value selected-language}
   (for [language languages]
     [:option {:key (:value language) :value (:value language)} (:text language)])])

(defn- single-input-view
  "HTML that is shared by the search views that only show a single text input,
  i.e., the simple and CQP views."
  [a {:keys [corpus] :as m} wrapped-query displayed-query
   show-remove-row-btn? show-checkboxes? on-text-changed]
  (let [query     (:query @wrapped-query)
        phonetic? (not= -1 (.indexOf query "phon="))]
    [:form.table-display {:style {:margin "10px 0px 15px -35px"}}
     [:div.table-row {:style {:margin-bottom 10}}
      [remove-row-btn show-remove-row-btn? wrapped-query]
      [b/input {:style            {:width 500}
                :class-name       "col-sm-12"
                :group-class-name "table-cell"
                :type             "text"
                :default-value    displayed-query
                :on-change        #(on-text-changed % wrapped-query phonetic?)
                :on-key-down      #(on-key-down % a m)}]]
     (when show-checkboxes?
       (list ^{:key 1}
             [:div.table-row
              [:div.table-cell]
              ;; ReactBootstrap doesn't seem to allow several checkboxes within the same
              ;; div.checkbox, since each [input {:type "checkbox"}] generates its own div.checkbox
              ;; wrapper (or is it possible somehow?), so we create the markup manually instead.
              [:div.checkbox {:style {:display "table-cell"}}
               (when (:has-phonetic @corpus)
                 [:label {:style {:margin-top 7}}
                  [:input {:name      "phonetic"
                           :type      "checkbox"
                           :checked   phonetic?
                           :on-change #(on-phonetic-changed % wrapped-query)}] " Phonetic form"])]]
             (when (:has-headword-search @corpus)
               ^{:key 2}
               [:div.table-row
                [:div.table-cell]
                [:div.table-cell {:style {:padding-left 20}}
                 [headword-search-checkbox wrapped-query]]])))]))

;;; The three different CWB interfaces: simple, extended and cqp

(defn- simple
  "Simple search view component"
  [a m wrapped-query show-remove-row-btn?]
  (let [query           (:query @wrapped-query)
        displayed-query (-> query
                            (->non-headword-query)
                            (str/replace #"\[\(?\w+=\"(.*?)\"(?:\s+%c)?\)?\]" "$1")
                            (str/replace #"\"([^\s=]+)\"" "$1")
                            (str/replace #"\s*\[\]\s*" " .* ")
                            (str/replace #"^\s*\.\*\s*$" ""))
        on-text-changed (fn [event wrapped-query phonetic?]
                          (let [value (.-target.value event)
                                query (if (= value "") "" (phrase->cqp value phonetic?))]
                            (swap! wrapped-query assoc :query query)))]
    [single-input-view a m wrapped-query displayed-query show-remove-row-btn?
     true on-text-changed]))


(defn- cqp
  "CQP query view component"
  [a m wrapped-query show-remove-row-btn?]
  (let [displayed-query (:query @wrapped-query)
        on-text-changed (fn [event wrapped-query _]
                          (let [value      (.-target.value event)
                                query      (->non-headword-query value)
                                hw-search? (= (->headword-query query) value)]
                            (swap! wrapped-query assoc :query query :headword-search hw-search?)))]
    [single-input-view a m wrapped-query displayed-query show-remove-row-btn?
     false on-text-changed]))

(defmethod search-inputs :default [_ _]
  "Component that lets the user select a search view (simple, extended
  or CQP query view) and displays it."
  (let [query-ids (atom nil)]
    (r/create-class
      {:display-name
       "search-inputs"

       :component-did-mount
       focus-text-input

       :reagent-render
       (fn [{{:keys [view-type queries]} :search-view :as a} {:keys [corpus] :as m}]
         (let [view          (case @view-type
                               :extended extended
                               :cqp cqp
                               simple)
               languages     (:langs @corpus)
               multilingual? (> (count languages) 1)
               set-view      (fn [view e] (reset! view-type view) (.preventDefault e))]
           [:span
            [:div.row.search-input-links>div.col-sm-12
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
             [search-button a m (if (= @view-type :extended) 72 233)]
             (when multilingual? [add-language-button])]

            ; Now create a cursor into the queries ratom for each search expression
            ; and display a row of search inputs for each of them. The doall call is needed
            ; because ratoms cannot be derefed inside lazy seqs.
            (let [nqueries             (count @queries)
                  query-range          (range nqueries)
                  show-remove-row-btn? (> nqueries 1)]
              ;; See explanation of query-term-ids in the extended view - query-ids is used
              ;; in the same way, but for queries instead of query terms
              (when (nil? @query-ids)
                (reset! query-ids (vec query-range)))
              (doall (for [index query-range
                           :let [query-id (nth @query-ids index)]]
                       ;; Use wrap rather than cursor to send individual queries down to
                       ;; child components (and in the extended view, we do the same for
                       ;; individual terms). When a query (or query term) changes, the wrap
                       ;; callbacks are called all the way up to the one setting the top-level
                       ;; queries ratom, and all query views (potentially) re-render.
                       ;;
                       ;; By using cursors we could have restricted re-rendering to smaller
                       ;; sub-views, but we need to do some processing of the query (such as
                       ;; changing " .* " to []) before updating it in the queries ratom.
                       ;; We could do this with a getter/setter-style cursor, but then we would
                       ;; have to update the queries ratom anyway, causing the same
                       ;; potential re-rendering of all query views.
                       ;;
                       ;; Probably the most efficient approach would be to use a standard cursor
                       ;; (which only re-renders the view that derefs it) and explicitly call the
                       ;; query processing function before updating the cursor, but then we would
                       ;; have to make sure to do that every time we change a query...
                       (let [wrapped-query     (r/wrap
                                                 (nth @queries index)
                                                 wrapped-query-changed queries
                                                 index query-ids)
                             selected-language (-> @wrapped-query :query :lang)]
                         ^{:key query-id}
                         [:div.row
                          [:div.col-sm-12
                           (when multilingual?
                             [language-select languages selected-language])
                           [view a m wrapped-query show-remove-row-btn?]]]))))
            (when-not multilingual? [add-phrase-button view])]))})))
