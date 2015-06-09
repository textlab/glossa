(ns cglossa.start
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]))

(defn- top []
  [:div.row-fluid
   [:div.span3.top-toolbar
    [:button#new-search-button.btn.btn-mini.btn-primary {:title "Reset form"} "Reset form"]]])

(defn- corpus-info [_ {:keys [corpus]}]
  [:div.row-fluid.corpus-info
   [:div.span12
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
