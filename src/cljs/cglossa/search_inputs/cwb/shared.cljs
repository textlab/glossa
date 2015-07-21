(ns cglossa.search-inputs.cwb.shared
  (:require [clojure.string :as str]
            [cljs-http.client :as http]))

(defn- search! [queries corpus]
  (let [queries*    @queries
        first-query (:query (first queries*))]
    (when (and first-query
               (not= first-query "\"\""))
      (let [q             (if (= (:lang corpus) "zh")
                            ;; For Chinese: If the tone number is missing, add a pattern
                            ;; that matches all tones
                            (for [query queries*]
                              (update query :query
                                      str/replace #"\bphon=\"([^0-9\"]+)\"" "phon=\"$1[1-4]?\""))
                            ;; For other languages, leave the queries unmodified
                            queries*)
            search-engine (:search-engine corpus "cwb")]
        (http/post "/search"
                   {:json-params {:corpus-rid (:rid @corpus)
                                  :queries q}})))))

(defn on-key-down [event wrapped-query corpus]
  (when (= "Enter" (.-key event))
    (.preventDefault event)
    (search! wrapped-query corpus)))

(defn remove-row-btn [show? wrapped-query]
  [:button.btn.btn-danger.btn-xs {:type     "button"
                                  :title    "Remove row"
                                  :on-click #(reset! wrapped-query nil)
                                  :style    {:margin-right 5
                                             :padding-top  3
                                             :visibility   (if show?
                                                             "visible"
                                                             "hidden")}}
   [:span.glyphicon.glyphicon-remove]])

(defn- on-headword-search-changed [event wrapped-query]
  (swap! wrapped-query assoc :headword-search (.-target.checked event)))

(defn headword-search-checkbox [wrapped-query margin-left]
  [:label {:style {:margin-left margin-left}}
   [:input {:type      "checkbox"
            :value     "1"
            :checked   (:headword-search @wrapped-query)
            :on-change #(on-headword-search-changed % wrapped-query)
            :id        "headword_search"
            :name      "headword_search"} " Headword search"]])
