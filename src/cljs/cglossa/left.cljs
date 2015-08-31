(ns cglossa.left
  (:require [reagent.core :as r]
            react-select))

(defn metadata-list [_ {:keys [metadata-categories]}]
  (let [select (r/adapt-react-class js/Select)]
    [:div#sidebar-wrapper
     (for [cat @metadata-categories]
       [select {:multi true
                :options   [{:value "one" :label "One"} {:value "two" :label "Two"}]
                :on-change #(.log js/console "endret")}])]))
