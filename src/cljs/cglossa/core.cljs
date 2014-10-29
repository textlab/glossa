(ns cglossa.core
  (:require [reagent.core :as reagent :refer [atom]]
            [plumbing.core :as plumbing :refer [map-vals]]
            [cglossa.start :as start]
            [cglossa.results :as results]))

; avoid "not resolved" messages in Cursive
(declare getElementById)

(def state {:showing-results? false
            :showing-sidebar? false
            :search-view :simple
            :search-queries [{:query "[word=\"han\" %c] [word=\"er\" %c]"}
                             {:query "[word=\"de\" %c] [word=\"sa\" %c]"}]})

(def data {:corpus {:name "Leksikografisk bokmålskorpus"
                    :code "bokmal"
                    :encoding "iso-8859-1"
                    :logo "book-clip-art-3.png"
                    :langs {:lang   :no
                            :tagger :obt_bm_lbk}}})

(defonce app-state (into {} (map-vals atom state)))
(defonce app-data (into {} (map-vals atom data)))

(defn header []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn app [{:keys [showing-results?] :as s} {:keys [corpus] :as d}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     [:div.container-fluid
      [:div.row-fluid
       [:div#main-content {:class-name cls}
        (if showing-results?
          [start/main s d]
          [results/main s d])]]]
     [:div.app-footer
      [:img.textlab-logo {:src "img/tekstlab.gif"}]]]))

(defn ^:export main []
  (reagent/render-component
    (fn []
      [app app-state app-data])
    (. js/document (getElementById "app"))))
