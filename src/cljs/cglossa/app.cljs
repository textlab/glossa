(ns cglossa.app
  (:require [cglossa.start :refer [start]]
            [cglossa.results :refer [results]]))

(defn- header []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn app [{:keys [showing-results?] :as s} {:keys [corpus] :as d}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     [:div.container-fluid
      [:div.row-fluid
       [:div#main-content {:class-name cls}
        (if @showing-results?
          [results s d]
          [start s d])]]]
     [:div.app-footer
      [:img.textlab-logo {:src "img/tekstlab.gif"}]]]))
