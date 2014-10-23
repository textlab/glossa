(ns cglossa.centre
  (:require [cglossa.start :as start]
            [cglossa.results :as results]))

(defn top [{:keys [showing-results? showing-sidebar?]}
           {:keys [corpus]}]
  [:div.row-fluid
   [:div.span3.top-toolbar
    [:button#new-search-button.btn.btn-mini.btn-primary {:title "Reset form"} "Reset form"]]
   (when @showing-results?
     [:div.span9 "No matches found"])])

(defn bottom [{:keys [showing-results?] :as s}
              {:keys [corpus] :as d}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div.row-fluid
     [:div#main-content {:class-name cls}
      (if @showing-results?
        [results/main s d]
        [start/main s d])]]))
