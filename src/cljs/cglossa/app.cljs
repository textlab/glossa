(ns cglossa.app
  (:require [cglossa.start :refer [start]]
            [cglossa.results :refer [results]]
            [cglossa.react-adapters.bootstrap :as b]))

(defn- header []
  [b/navbar {:fixedTop true :brand "Glossa"}])

(defn- main-area [{:keys [showing-results?] :as a} m]
  [:div.container-fluid {:style {:padding-left 50}}
      [:div.row>div#main-content.col-md-12
       (if @showing-results?
         [results a m]
         [start a m])]])

(defn app [a {:keys [corpus] :as m}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     (when @corpus
       [main-area a m])
     [:div.app-footer>img.textlab-logo {:src "img/tekstlab.gif"}]]))
