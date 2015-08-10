(ns cglossa.shared
  (:require [cglossa.react-adapters.bootstrap :as b]))

(defn top-toolbar [{:keys [search-queries num-resets]}]
  [:div.col-sm-3
   [b/buttontoolbar {:style {:margin-bottom 20}}
    [b/button {:bs-style "primary"
               :bs-size  "xsmall"
               :title    "Reset form"
               :on-click (fn []
                           (reset! search-queries [{:query ""}])
                           (swap! num-resets inc))}         ; see comments in the start component
     "Reset form"]]])
