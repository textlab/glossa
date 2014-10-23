(ns cglossa.core
  (:require [reagent.core :as reagent :refer [atom]]
            [plumbing.core :as plumbing :refer [map-vals]]
            [cglossa.centre :as centre]))

; avoid "not resolved" messages in Cursive
(declare getElementById)

(def state {:showing-results? false
            :showing-sidebar? false
            :search-query {:query "[word=\"han\" %c] [word=\"er\" %c]"}})

(def data {:corpus {:name "Leksikografisk bokmålskorpus"
                    :code "bokmal"
                    :encoding "iso-8859-1"
                    :logo "book-clip-art-3.png"
                    :languages {:lang   :no
                                :tagger :obt_bm_lbk}}})

(defonce app-state (into {} (map-vals atom state)))
(defonce app-data (into {} (map-vals atom data)))

(defn header []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn app [s d]
  [:div
   [header]
   [:div.container-fluid
    [centre/top s d]
    [centre/bottom s d]]
   [:div.app-footer
    [:img.textlab-logo {:src "img/tekstlab.gif"}]]])

(defn ^:export main []
  (reagent/render-component
    (fn []
      [app app-state app-data])
    (. js/document (getElementById "app"))))
