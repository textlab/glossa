(ns cglossa.result-views.cwb.core
  (:require [clojure.string :as str]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.results :refer [concordance-table]]))

(defmulti concordance-rows
  "Multimethod that returns one or more rows representing a single search result."
  (fn [_ {corpus :corpus} _ _] (keyword (:search-engine @corpus))))

(defmethod concordance-table :default [{{:keys [results page-no]} :results-view :as a} m]
  (let [res (get @results @page-no)]
    [:div.row>div.col-sm-12.search-result-table-container
     [b/table {:striped true :bordered true}
      [:tbody
       (doall (map (partial concordance-rows a m)
                   res
                   (range (count res))))]]]))
