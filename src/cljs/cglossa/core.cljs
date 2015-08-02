(ns cglossa.core
  (:require [reagent.core :as r]
            [cljs-http.client :as http]
            [cljs.core.async :refer [<!]]
            [cglossa.app :refer [app]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

; avoid "not resolved" messages in Cursive
(declare getElementById)

(def state {:showing-sidebar? false
            :showing-results? false
            :showing-freqs?   false
            :search-view      :simple
            :search-queries   [#_{:query "[word=\"han\" %c] []{1,2} [word=\"er\" %c]"}
                               {:query "[word=\"de\" %c] [word=\"sa\" %c]"}
                               #_{:query "[word=\"hun\" %c] [word=\"vet\" %c]"}]})

(def data {:corpus              nil
           :metadata-categories nil
           :search-results      nil})

(defonce app-state (into {} (map (fn [[k v]] [k (r/atom v)]) state)))
(defonce model-state (into {} (map (fn [[k v]] [k (r/atom v)]) data)))

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
