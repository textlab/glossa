(ns cglossa.app
  (:require [cglossa.start :refer [start]]
            [cglossa.results :refer [results]]))

(defn- header []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn app [{:keys [showing-results?] :as a} {:keys [corpus] :as m}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     [:div.container-fluid
      [:div.row-fluid
       [:div#main-content {:class-name cls}
        (if @showing-results?
          [results a m]
          [start a m])]]]
     [:div.app-footer
      [:img.textlab-logo {:src "img/tekstlab.gif"}]]]))
