(ns cglossa.left
  (:require [reagent.core :as r]
            [cglossa.select2 :refer [select2]]))

(defn metadata-list [_ {:keys [metadata-categories]}]
  [:div#sidebar-wrapper
   (for [cat @metadata-categories]
     ^{:key (:rid cat)}
     [select2 (r/atom {:a "A" :b "B"}) (r/atom nil) {:placeholder (:name cat)}
      [:div
       [:select.list {:style {:width "100%"} :multiple true}]]])])
