(ns cglossa.shared
  (:require [cglossa.react-adapters.bootstrap :as b]))

(defn top-toolbar [{:keys [num-resets showing-sidebar? narrow-view?] {queries :queries}
                          :search-view}]
  [:div.col-sm-5
   [b/buttontoolbar {:style {:margin-bottom 20}}
    (if @showing-sidebar?
      [b/button {:bs-size  "xsmall"
                 :title    "Hide search criteria"
                 :on-click (fn [e]
                             (reset! showing-sidebar? false)
                             (.preventDefault e))}
       "Hide filters"]
      [b/button {:bs-size  "xsmall"
                 :title    "Show search criteria"
                 :on-click (fn [e]
                             (reset! showing-sidebar? true)
                             (.preventDefault e))}
       "Filters"])
    [b/button {:bs-style "primary"
               :bs-size  "xsmall"
               :title    "Reset form"
               :on-click (fn []
                           (reset! queries [{:query ""}])
                           (swap! num-resets inc))}         ; see comments in the start component
     "Reset form"]]])
