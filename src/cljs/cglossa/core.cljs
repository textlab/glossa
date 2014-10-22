(ns cglossa.core
  (:require [reagent.core :as reagent :refer [atom]]
            [plumbing.core :as plumbing :refer [map-vals]]))

(defonce app-state (atom {:text "Hello Chestnut!"}))

(defn navbar []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand Glossa]]]])

(defn top []
  [:div.row-fluid
   [:div.span3.top-toolbar
    [:button#new-search-button.btn.btn-mini.btn-primary {:title "Reset form" :value "Reset form"}]
    [:div.span9]]])

(defn middle []
  [:div "middle"])

(defn bottom []
  [:div "bottom"])

(defn app []
  [:div [navbar]
   [:div.container-fluid
    [top]
    [middle]]
   [bottom]])

(defn ^:export main []
  (reagent/render-component
    (fn []
      [app])
    (. js/document (getElementById "app"))))
