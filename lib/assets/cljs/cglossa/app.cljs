(ns cglossa.app
  (:require [cglossa.left :refer [metadata-list]]
            [cglossa.start :refer [start]]
            [cglossa.results :refer [results]]
            [cglossa.react-adapters.bootstrap :as b]))

(defn- header []
  [b/navbar {:fixedTop true :brand "Glossa"}])

(defn- main-area [{{:keys [show?]} :results-view :as a} m]
  [:div#page-content-wrapper
   [:div.container-fluid {:style {:padding-left 50}}
    [:div.row>div#main-content.col-sm-12
     (if @show?
       [results a m]
       [start a m])]]])

(defn app [{:keys [showing-sidebar? narrow-view?] :as a} {:keys [corpus] :as m}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     (when @corpus
       [:div#wrapper {:class-name (when (or @showing-sidebar? (not @narrow-view?)) "toggled")}
        [metadata-list a m]
        [main-area a m]])
     [:div.app-footer>img.textlab-logo {:src "img/tekstlab.gif"}]]))
