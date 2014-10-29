(ns cglossa.search-inputs.cwb
  (:require [clojure.string :as str]
            [reagent.core :as reagent :refer [cursor]]))

(defn- phrase->cqp [phrase phonetic?]
  (let [attr (if phonetic? "phon" "word")
        chinese-chars-range "[\u4E00-\u9FFF\u3400-\u4DFF\uF900-\uFAFF]"
        ; Surround every Chinese character by space when constructing a cqp query,
        ; to treat it as if it was an individual word:
        phrase (str/replace phrase (re-pattern (str "(" chinese-chars-range ")")) " $1 ")]
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
  (let [query (:query @query-cursor)
        checked? (aget event "target" "checked")
        query (if checked?
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
  [:button.btn.btn-success {:style {:marginLeft (if multilingual? 80 40)}
                            :on-click search!} "Search"])

(defn- add-language-button []
  [:button.btn {:style {:marginLeft 20} :on-click #()} "Add language"])

(defn- add-phrase-button []
  [:button.btn.add-phrase-btn {:on-click #()} "Or..."])

(defn- language-select [languages selected-language]
  [:select {:value selected-language}
   (for [language languages]
     [:option {:key (:value language) :value (:value language)} (:text language)])])

(defn- simple [query-cursor]
  [:span "hallo"]
  (let [query (:query @query-cursor)
        displayed-query (str/replace query #"\[\(?\w+=\"(.+?)\"(?:\s+%c)?\)?\]" "$1")
        phonetic? (not= -1 (.indexOf query "phon="))]
    [:div.row-fluid
     [:form.form-inline.span12
      [:div.span10
       [:input.span12 {:type        "text" :value displayed-query
                       :on-change   #(on-text-changed % query-cursor phonetic?)
                       :on-key-down #(on-key-down % query-cursor)}]
       [:label {:style {:marginTop 5}}
        [:input {:name      "phonetic" :type "checkbox"
                 :style     {:marginTop -3} :checked phonetic?
                 :on-change #(on-phonetic-changed % query-cursor)} " Phonetic form"]]]]]))

(defn search-inputs [{:keys [search-view search-queries]} {:keys [corpus]}]
  [:span "heidu"]
  (let [view @search-view
        languages (:langs @corpus)
        multilingual? (> (count languages) 1)]
    [:span
     [:div.row-fluid.search-input-links
      (if (= view :simple)
        [:b "Simple"]
        [:a {:href "" :title "Simple search box" :on-click #()} "Simple"])
      " | "
      (if (= view :extended)
        [:b "Extended"]
        [:a {:href "" :title "Search for grammatical categories etc." :on-click #()} "Extended"])
      " | "
      (if (= view :cqp)
        [:b "CQP"]
        [:a {:href "" :title "CQP expressions" :on-click #()} "CQP"])
      [search-button multilingual?]
      (when multilingual? [add-language-button])]

     ; Now create a cursor into the search-queries ratom for each search expression
     ; and display a row of search inputs for each of them. The doall call is needed
     ; because ratoms cannot be derefed inside lazy seqs.
     (doall (for [index (range (count @search-queries))]
              (let [query-cursor (cursor [index] search-queries)
                    selected-language (-> @query-cursor :query :lang)]
                (when multilingual? [language-select languages selected-language])
                [simple query-cursor multilingual?])))
     (when-not multilingual? [add-phrase-button])]))

