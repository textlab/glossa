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

(defonce app-state {:narrow-view?      (r/atom (narrow-view?))
                    :showing-sidebar?  (r/atom false)
                    :results-view      {:show?             (r/atom false)
                                        :results           (r/atom nil)
                                        :total             (r/atom 0)
                                        :page-no           (r/atom 1)
                                        :paginator-page-no (r/atom 1)
                                        :sort-by           (r/atom :position)
                                        :freq-attr         (r/atom nil)
                                        :media             {:player-row-index    (r/atom nil)
                                                            :current-player-type (r/atom nil)
                                                            :current-media-type  (r/atom nil)}}
                    :search-view       {:view-type (r/atom :simple)
                                        :queries   (r/atom [#_{:query "[word=\"han\" %c] []{1,2} [word=\"er\" %c]"}
                                                            #_{:query "[word=\"de\" %c] [word=\"sa\" %c]"}
                                                            {:query "[word=\"hun\" %c] [word=\"vet\" %c]"}])}
                    :searching?        (r/atom false)
                    :open-metadata-cat (r/atom nil)
                    :num-resets        (r/atom 0)})

(defonce model-state {:corpus              (r/atom nil)
                      :metadata-categories (r/atom nil)
                      :search              (atom {})})

;; Set :narrow-view in app-state whenever the window is resized (throttled to 200ms)
(def on-resize-throttle (Throttle. #(reset! (:narrow-view? app-state) (narrow-view?)) 200))
(.addEventListener js/window "resize" #(.fire on-resize-throttle))

(defn- get-models
  ([url] (get-models url {}))
  ([url params]
   (go (let [response (<! (http/get url {:query-params params :headers {"Accept" "application/json"}}))
             body     (:body response)]
         (doseq [[model-name data] body]
           (if (http/unexceptional-status? (:status response))
             (reset! (get model-state model-name) data)
             (.error js/console (str "Error: " body))))))))

(if-let [corpus (second (re-find #"corpus=(\w+)" (.-location.search js/window)))]
  (get-models "corpora/find_by" {:short_name corpus})
  (js/alert "Please provide a corpus in the query string (on the form corpus=mycorpus)"))

(defn ^:export main []
  (r/render
    [app app-state model-state]
    (. js/document (getElementById "app"))))

(main)
