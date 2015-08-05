(ns cglossa.search-inputs.cwb.shared
  (:require-macros [cljs.core.async.macros :refer [go]])
  (:require [clojure.string :as str]
            [cljs-http.client :as http]
            [cljs.core.async :refer [<!]]
            [cglossa.react-adapters.bootstrap :as b]))

(defn- cleanup-result [result]
  (-> result
      ;; Remove the beginning of the search result, which will be a position number in the
      ;; case of a monolingual result or the first language of a multilingual result, or
      ;; an arrow in the case of subsequent languages in a multilingual result.
      (str/replace #"^\s*\d+:\s*" "")
      (str/replace #"^-->.+?:\s*" "")
      ;; When the match includes the first or last token of the s unit, the XML tag surrounding
      ;; the s unit is included inside the match braces (this should probably be considered a bug
      ;; in CQP). We need to fix that.
      (str/replace #"\{\{(<s_id\s+.+?>)" "$1{{")
      (str/replace #"(</s_id>)\}\}" "}}$1")))

(defn- search! [{:keys [search-queries]} {:keys [corpus search-results]}]
  (let [queries     @search-queries
        first-query (:query (first queries))]
    (when (and first-query
               (not= first-query "\"\""))
      (let [q             (if (= (:lang corpus) "zh")
                            ;; For Chinese: If the tone number is missing, add a pattern
                            ;; that matches all tones
                            (for [query queries]
                              (update query :query
                                      str/replace #"\bphon=\"([^0-9\"]+)\"" "phon=\"$1[1-4]?\""))
                            ;; For other languages, leave the queries unmodified
                            queries)
            search-engine (:search-engine corpus "cwb")]
        (go (let [{:keys [status success] :as response}
                  (<! (http/post "/search"
                                 {:json-params {:corpus-id (:rid @corpus)
                                                :queries   q}}))]
              (if success
                (let [results (get-in response [:body :results])]
                  (reset! search-results (map cleanup-result results)))
                (.log js/console status))))))))

(defn on-key-down [event wrapped-query corpus]
  (when (= "Enter" (.-key event))
    (.preventDefault event)
    (search! wrapped-query corpus)))

(defn remove-row-btn [show? wrapped-query]
  [:div.table-cell.remove-row-btn-container
   [b/button {:bs-style "danger"
              :bs-size  "xsmall"
              :title    "Remove row"
              :on-click #(reset! wrapped-query nil)
              :style    {:margin-right 5
                         :padding-top  3
                         :visibility   (if show?
                                         "visible"
                                         "hidden")}}
    [b/glyphicon {:glyph "remove"}]]])

(defn headword-search-checkbox [wrapped-query margin-left]
  [:label {:style {:margin-left margin-left}}
   [:input {:type      "checkbox"
            :value     "1"
            :checked   (:headword-search @wrapped-query)
            :on-change #(swap! wrapped-query assoc :headword-search (.-target.checked %))
            :id        "headword_search"
            :name      "headword_search"} " Headword search"]])
