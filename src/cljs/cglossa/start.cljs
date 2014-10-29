(ns cglossa.start
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]))

(defn- corpus-info [s {:keys [corpus]}]
  [:div.row-fluid.corpus-info
   [:div.span12
    [:div.well
     [:h2
      (:name @corpus)
      (when-let [logo (:logo @corpus)]
        [:img.corpus-logo {:src (str "img/" logo)}])]]]])

(defn main [s {:keys [corpus] :as d}]
  (let [search-interface (search-interface-for-corpus corpus)]
    [:div
     [corpus-info s d]
     [:div [search-interface s d]]]))
