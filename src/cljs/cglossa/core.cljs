(ns cglossa.core
  (:require [reagent.core :as reagent :refer [atom]]
            [plumbing.core :as plumbing :refer [map-vals]]
            [cglossa.centre :as centre]))

(def state {:showing-results false})

(def data {:categories ["ku" "hest"]
           :users      ["per" "kari"]})

(defonce app-state (into {} (map-vals atom state)))
(defonce app-data (into {} (map-vals atom data)))

(defn navbar []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn bottom [_ {:keys [categories]}]
  [:div (for [cat @categories]
     [:div cat])])

(defn app [s d]
  [:div
   [navbar]
   [:div.container-fluid
    [centre/top s d]]
   [bottom s d]])

(defn ^:export main []
  (reagent/render-component
    (fn []
      [app app-state app-data])
    (. js/document (getElementById "app"))))
