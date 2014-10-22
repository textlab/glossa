(ns cglossa.core
  (:require [reagent.core :as reagent :refer [atom]]
            [plumbing.core :as plumbing :refer [map-vals]]))

(def data {:categories ["ku" "hest"]
           :users      ["per" "kari"]})

(defonce app-state (into {} (map-vals atom data)))

(defn navbar []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn top []
  [:div.row-fluid
   [:div.span3.top-toolbar
    [:button#new-search-button.btn.btn-mini.btn-primary {:title "Reset form" :value "Reset form"}]
    [:div.span9]]])

(defn bottom [{:keys [categories]}]
  [:div (for [cat @categories]
     [:div cat])])

(defn app [s]
  (.log js/console s)
  [:div [navbar]
   [:div.container-fluid
    [top]]
   [bottom s]])

(defn ^:export main []
  (reagent/render-component
    (fn []
      [app app-state])
    (. js/document (getElementById "app"))))
