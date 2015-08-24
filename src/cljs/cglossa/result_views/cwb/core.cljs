(ns cglossa.result-views.cwb.core
  (:require [clojure.string :as str]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.results :refer [concordance-table]]))

(defmulti concordance-rows
  "Multimethod that returns one or more rows representing a single search result."
  (fn [_ {corpus :corpus} _ _] (keyword (:search-engine @corpus))))

(defmethod concordance-table :default [{:keys [search-results] :as a} {:keys [corpus] :as m}]
  (let [results @search-results]
    [:div.row>div.col-sm-12 {:style {:height 320 :overflow "auto"}}
     [b/table {:striped true :bordered true}
      [:tbody
       (map (partial concordance-rows a m)
            results
            (range (count results)))]]]))
