(ns cglossa.search-views.cwb.shared
  (:require-macros [cljs.core.async.macros :refer [go]])
  (:require [clojure.string :as str]
            [cljs-http.client :as http]
            [cljs.core.async :refer [<!]]
            [cglossa.react-adapters.bootstrap :as b]))

(defn- cleanup-result [result]
  (update result :text
          #(-> %
               ;; Remove the beginning of the search result, which will be a position number in the
               ;; case of a monolingual result or the first language of a multilingual result, or
               ;; an arrow in the case of subsequent languages in a multilingual result.
               (str/replace #"^\s*\d+:\s*" "")
               (str/replace #"^-->.+?:\s*" "")
               ;; When the match includes the first or last token of the s unit, the XML tag
               ;; surrounding the s unit is included inside the match braces (this should probably
               ;; be considered a bug in CQP). We need to fix that.
               (str/replace #"\{\{(<s_id\s+.+?>)" "$1{{")
               (str/replace #"(</s_id>)\}\}" "}}$1"))))

;; TODO: Make this configurable?
(def page-size 50)

(defn- search-step3 [url params total searching? search-id]
  "Performs an unrestricted search."
  (go
    (let [results-ch (http/post url {:json-params (merge params {:step      3
                                                                 :cut       nil
                                                                 :search-id search-id})})
          {:keys [status success] {res :result} :body} (<! results-ch)]
      (if-not success
        (.log js/console status)
        (do
          ;; The results from the third request should be the number of results found so far.
          ;; Just set the total ratom (we'll postpone fetching any results until the user switches
          ;; to a different result page) and mark searching as finished.
          (reset! total res)
          (reset! searching? false))))))

(defn- search-step2 [url params total searching? search-id]
  "Performs a search restricted to 20 pages of search results."
  (go
    (let [results-ch (http/post url {:json-params (merge params {:step      2
                                                                 :cut       (* 20 page-size)
                                                                 :search-id search-id})})
          {:keys [status success] {res :result} :body} (<! results-ch)]
      (if-not success
        (.log js/console status)
        (do
          ;; The response from the second request should be the number of results found so far.
          ;; Just set the total ratom - we'll postpone fetching any results until the user switches
          ;; to a different result page.
          (reset! total res)
          (if (< res (* 20 page-size))
            ;; We found less than 20 search pages of results, so stop searching
            (reset! searching? false)
            (search-step3 url params total searching? search-id)))))))

(defn- search-step1 [url params total searching? current-search current-results]
  "Performs a search restricted to one page of search results."
  (go
    (let [results-ch (http/post url {:json-params (merge params {:step 1 :cut page-size})})
          {:keys [status success] {:keys [search result]} :body :as response} (<! results-ch)]
      (if-not success
        (.log js/console status)
        (do
          (swap! current-search merge search)
          ;; The response from the first request should be (at most) one page of search results.
          ;; Set the results ratom to those results and the total ratom to the number of results.
          (reset! current-results {1 (map cleanup-result result)})
          (reset! total (count result))
          (if (< (count result) page-size)
            ;; We found less than one search page of results, so stop searching
            (reset! searching? false)
            (search-step2 url params total searching? (:rid search))))))))

(defn- search! [{{queries :queries}                  :search-view
                 {:keys [show? results total page-no
                         paginator-page-no sort-by]} :results-view
                 searching?                          :searching?}
                {:keys [corpus search]}]
  (let [first-query (:query (first @queries))]
    (when (and first-query
               (not= first-query "\"\""))
      (let [q      (if (= (:lang @corpus) "zh")
                     ;; For Chinese: If the tone number is missing, add a pattern
                     ;; that matches all tones
                     (for [query @queries]
                       (update query :query
                               str/replace #"\bphon=\"([^0-9\"]+)\"" "phon=\"$1[1-4]?\""))
                     ;; For other languages, leave the queries unmodified
                     @queries)
            url    "/search"
            params {:corpus-id (:rid @corpus)
                    :queries   q
                    :sort-by   @sort-by}]
        (reset! show? true)
        (reset! results nil)
        (reset! searching? true)
        (reset! total 0)
        (reset! page-no 1)
        (reset! paginator-page-no 1)
        (search-step1 url params total searching? search results)))))

(defn on-key-down [event a m]
  (when (= "Enter" (.-key event))
    (.preventDefault event)
    (search! a m)))

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

(defn headword-search-checkbox [wrapped-query]
  [b/input {:type      "checkbox"
            :value     "1"
            :checked   (:headword-search @wrapped-query)
            :on-change #(swap! wrapped-query assoc :headword-search (.-target.checked %))
            :id        "headword_search"
            :name      "headword_search"} " Headword search"])
