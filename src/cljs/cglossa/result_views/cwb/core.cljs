(ns cglossa.result-views.cwb.core
  (:require [clojure.string :as str]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.results :refer [concordance-table]]))

(defmulti concordance-rows
  "Multimethod that returns one or more rows representing a single search result."
  (fn [_ {corpus :corpus} _ _] (keyword (:search-engine @corpus))))

(defmethod concordance-table :default [{{results :results} :results-view :as a}
                                       {:keys [corpus] :as m}]
  (let [res @results]
    [:div.row>div.col-sm-12.search-result-table-container {:style {:height 320 :overflow "auto"}}
     [b/table {:striped true :bordered true}
      [:tbody
       (doall (map (partial concordance-rows a m)
                   res
                   (range (count res))))]]]))
