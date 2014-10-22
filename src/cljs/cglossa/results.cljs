(ns cglossa.results
  (:require [cglossa.search-inputs :as search-inputs]))

(defn main [_ {:keys [corpus]}]
  (let [search-engine (get @corpus :search-engine :cwb)
        component (get search-inputs/components search-engine)]
    [:div [component]]))
