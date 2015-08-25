(ns cglossa.core
  (:require [reagent.core :as r]
            [cljs-http.client :as http]
            [cljs.core.async :refer [<!]]
            [devtools.core :as devtools]
            [cglossa.search-engines]                        ; just to pull in implementations
            [cglossa.app :refer [app]])
  (:require-macros [cljs.core.async.macros :refer [go]])
  (:import [goog Throttle]))

(devtools/install!)

(defn narrow-view? []
  (< (.-innerWidth js/window) 768))

(def state {:narrow-view?        (narrow-view?)
            :showing-sidebar?    false
            :showing-results?    false
            :sort-results-by     :position
            :freq-attr           nil
            :search-view         :simple
            :search-queries      [#_{:query "[word=\"han\" %c] []{1,2} [word=\"er\" %c]"}
                                  #_{:query "[word=\"de\" %c] [word=\"sa\" %c]"}
                                  {:query "[word=\"hun\" %c] [word=\"vet\" %c]"}]
            :search-results      nil
            :player-row-index    nil
            :current-player-type nil
            :current-media-type  nil
            :num-resets          0})

(def data {:corpus              nil
           :metadata-categories nil})

(defonce app-state (into {} (map (fn [[k v]] [k (r/atom v)]) state)))
(defonce model-state (into {} (map (fn [[k v]] [k (r/atom v)]) data)))

;; Set :narrow-view in app-state whenever the window is resized (throttled to 200ms)
(def on-resize-throttle (Throttle. #(reset! (:narrow-view? app-state) (narrow-view?)) 200))
(.addEventListener js/window "resize" #(.fire on-resize-throttle))

(defn- get-models
  ([url] (get-models url {}))
  ([url params]
   (go (let [response (<! (http/get url {:query-params params}))
             body     (:body response)]
         (doseq [[model-name data] body]
           (if (http/unexceptional-status? (:status response))
             (reset! (get model-state model-name) data)
             (.error js/console (str "Error: " body))))))))

(get-models "/corpus" {:code "scandiasyn"})

(defn ^:export main []
  (r/render
    [app app-state model-state]
    (. js/document (getElementById "app"))))

(main)
