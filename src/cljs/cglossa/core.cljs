(ns cglossa.core
  (:require [reagent.core :as r]
            [ajax.core :as ajax]
            [cglossa.start :as start]
            [cglossa.results :as results]))

; avoid "not resolved" messages in Cursive
(declare getElementById)

(def state {:showing-results? false
            :showing-sidebar? false
            :search-view      :simple
            :search-queries   [{:query "[word=\"han\" %c] [word=\"er\" %c]"}
                               {:query "[word=\"de\" %c] [word=\"sa\" %c]"}]})

(def data {:corpus nil
           :metadata-categories nil})

(defonce app-state (into {} (map (fn [[k v]] [k (r/atom v)]) state)))
(defonce app-data (into {} (map (fn [[k v]] [k (r/atom v)]) data)))

(defn response-handler [models response]
  (doseq [model (flatten [models])]
    (reset! (get app-data model) (get response model))))

(defn error-handler [{:keys [status status-text]}]
  (.log js/console (str "Error: " status " " status-text)))

(ajax/GET "/corpus" {:params          {:code "bokmal"}
                     :handler         (partial response-handler [:corpus :metadata-categories])
                     :error           error-handler
                     :response-format (ajax/transit-response-format)})

(defn- header []
  [:div.navbar.navbar-fixed-top [:div.navbar-inner [:div.container [:span.brand "Glossa"]]]])

(defn app [{:keys [showing-results?] :as s} {:keys [corpus] :as d}]
  (let [cls (if (empty? (:metadata-categories @corpus)) "span12" "span9")]
    [:div
     [header]
     [:div.container-fluid
      [:div.row-fluid
       [:div#main-content {:class-name cls}
        (if @showing-results?
          [results/main s d]
          [start/main s d])]]]
     [:div.app-footer
      [:img.textlab-logo {:src "img/tekstlab.gif"}]]]))

(defn ^:export main []
  (r/render-component
    (fn []
      [app app-state app-data])
    (. js/document (getElementById "app"))))

(main)
