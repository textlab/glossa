(ns cglossa.start
  (:require [cglossa.search-inputs :as search-inputs]))

(defn- corpus-info [s {:keys [corpus]}]
  [:div.row-fluid.corpus-info
   [:div.span12
    [:div.well
     [:h2
      (:name @corpus)
      (when-let [logo (:logo @corpus)]
        [:img.corpus-logo {:src (str "img/" logo)}])]]]])

(defn main [s {:keys [corpus] :as d}]
  (let [search-engine (get @corpus :search-engine :cwb)
        component (get search-inputs/components search-engine)]
    [:div
     [corpus-info s d]
     [:div [component s d]]]))
