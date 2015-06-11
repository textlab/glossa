(ns cglossa.start
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]))

(defn- top []
  [:div.row
   [:div.col-md-3.top-toolbar
    [:button#new-search-button.btn.btn-xs.btn-primary {:title "Reset form"} "Reset form"]]])

(defn- corpus-info [_ {:keys [corpus]}]
  [:div.row.corpus-info
   [:div.col-md-12
    [:div.well
     [:h2
      (:name @corpus)
      (when-let [logo (:logo @corpus)]
        [:img.corpus-logo {:src (str "img/" logo)}])]]]])

(defn start [a {:keys [corpus] :as m}]
  (let [search-interface (search-interface-for-corpus corpus)]
    [:div
     [top]
     [corpus-info a m]
     [search-interface a m]]))
