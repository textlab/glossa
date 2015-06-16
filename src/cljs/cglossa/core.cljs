(ns cglossa.core
  (:require [reagent.core :as reagent]
            [ajax.core :as ajax]
            [cglossa.app :refer [app]]))

; avoid "not resolved" messages in Cursive
(declare getElementById)

(def state {:showing-results? false
            :showing-sidebar? false
            :search-view      :simple
            :search-queries   [{:query "[word=\"han\" %c] [word=\"er\" %c]"}
                               {:query "[word=\"de\" %c] [word=\"sa\" %c]"}
                               {:query "[word=\"hun\" %c] [word=\"vet\" %c]"}]})

(def data {:corpus nil
           :metadata-categories nil})

(defonce app-state (into {} (map (fn [[k v]] [k (reagent/atom v)]) state)))
(defonce model-state (into {} (map (fn [[k v]] [k (reagent/atom v)]) data)))

(defn response-handler [models response]
  (doseq [model (flatten [models])]
    (reset! (get model-state model) (get response model))))

(defn error-handler [{:keys [status status-text]}]
  (.log js/console (str "Error: " status " " status-text)))

(ajax/GET "/corpus" {:params          {:code "scandiasyn"}
                     :handler         (partial response-handler [:corpus :metadata-categories])
                     :error           error-handler
                     :response-format (ajax/transit-response-format)})

(defn ^:export main []
  (reagent/render-component
    [app app-state model-state]
    (. js/document (getElementById "app"))))

(main)
