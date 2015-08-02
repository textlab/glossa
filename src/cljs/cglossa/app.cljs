(ns cglossa.app
  (:require [cglossa.start :refer [start]]
            [cglossa.results :refer [results]]
            [cglossa.react-adapters.bootstrap :refer [navbar]]))

(defn- header []
  [navbar {:fixedTop true :brand "Glossa"}])

(defn app [{:keys [showing-results?] :as a} {:keys [corpus] :as m}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     [:div.container-fluid {:style {:padding-left 45}}
      [:div.row>div#main-content.col-md-12
       (if @showing-results?
         [results a m]
         [start a m])]]
     [:div.app-footer>img.textlab-logo {:src "img/tekstlab.gif"}]]))
