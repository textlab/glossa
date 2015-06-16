(ns cglossa.search-inputs.cwb
  (:require [clojure.string :as str]
            [reagent.core :as reagent]))

(defn- phrase->cqp [phrase phonetic?]
  (let [attr                (if phonetic? "phon" "word")
        chinese-chars-range "[\u4E00-\u9FFF\u3400-\u4DFF\uF900-\uFAFF]"
        ; Surround every Chinese character by space when constructing a cqp query,
        ; to treat it as if it was an individual word:
        phrase              (str/replace phrase
                                         (re-pattern (str "(" chinese-chars-range ")"))
                                         " $1 ")]
    (->> (str/split phrase #"\s")
         (map #(if (= % "")
                ""
                (str "[" attr "=\"" % "\" %c]")))
         (str/join " "))))

(defn- search! [query-cursor]
  (.log js/console "soker"))

;;;;;;;;;;;;;;;;;
; Event handlers
;;;;;;;;;;;;;;;;;

(defn- on-text-changed [event query-cursor phonetic?]
  (let [value (aget event "target" "value")
        query (if (= value "")
                ""
                (phrase->cqp value phonetic?))]
    (swap! query-cursor assoc-in [:query] query)))

(defn- on-phonetic-changed [event query-cursor]
  (let [query    (:query @query-cursor)
        checked? (aget event "target" "checked")
        query    (if checked?
                   (str/replace query "word=" "phon=")
                   (str/replace query "phon=" "word="))]
    (swap! query-cursor assoc-in [:query] query)))

(defn- on-key-down [event query-cursor]
  (when (= "Enter" (aget event "key"))
    (.preventDefault event)
    (search! query-cursor)))

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

(defn- simple [query-cursor show-remove-btn? remove-query-handler]
  (let [query           (:query @query-cursor)
        displayed-query (str/replace query #"\[\(?\w+=\"(.+?)\"(?:\s+%c)?\)?\]" "$1")
        phonetic?       (not= -1 (.indexOf query "phon="))]
    [:form {:style {:display "table" :margin-left -30 :margin-bottom 20}}
     [:div {:style {:display "table-row" :margin-bottom 10}}
      [:div {:style {:display "table-cell"}}
       [:button.btn.btn-default.btn-xs {:type     "button"
                                        :title    "Remove row"
                                        :on-click #(remove-query-handler)
                                        :style    {:margin-right 5
                                                   :margin-top   -25
                                                   :visibility   (if show-remove-btn?
                                                                   "visible"
                                                                   "hidden")}}
        [:span.glyphicon.glyphicon-remove]]]
      [:div.form-group {:style {:display "table-cell"}}
       [:input.form-control.col-md-12 {:style       {:width 500}
                                       :type        "text"
                                       :value       displayed-query
                                       :on-change   #(on-text-changed % query-cursor phonetic?)
                                       :on-key-down #(on-key-down % query-cursor)}]]]
     [:div {:style {:display "table-row"}}
      [:div {:style {:display "table-cell"}}]
      [:div.checkbox {:style {:display "table-cell"}}
       [:label
        [:input {:name      "phonetic"
                 :type      "checkbox"
                 :checked   phonetic?
                 :on-change #(on-phonetic-changed % query-cursor)}] " Phonetic form"]]]]))

(defn- extended [query-cursor]
  [:span])

(defn- cqp [query-cursor]
  [:span])

(defn search-inputs [{:keys [search-view search-queries]} {:keys [corpus]}]
  (let [view          (case @search-view
                        :extended extended
                        :cqp cqp
                        simple)
        languages     (:langs @corpus)
        multilingual? (> (count languages) 1)
        set-view      (fn [view e] (reset! search-view view) (.preventDefault e))]
    [:span
     [:div.search-input-links
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
      (when multilingual? [add-language-button])]

     ; Now create a cursor into the search-queries ratom for each search expression
     ; and display a row of search inputs for each of them. The doall call is needed
     ; because ratoms cannot be derefed inside lazy seqs.
     (let [nqueries         (count @search-queries)
           show-remove-btn? (> nqueries 1)
           remove-query     (fn [i] (swap! search-queries
                                           #(vec (concat (subvec % 0 i) (subvec % (inc i))))))]
       (doall (for [index (range nqueries)]
                (let [query-cursor         (reagent/cursor search-queries [index])
                      selected-language    (-> @query-cursor :query :lang)
                      remove-query-handler (partial remove-query index)]
                  (when multilingual? [language-select languages selected-language])
                  ^{:key index} [view query-cursor show-remove-btn? remove-query-handler]))))
     (when-not multilingual? [add-phrase-button])]))
