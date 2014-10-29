(ns cglossa.results
  (:require [cglossa.search-inputs.core :as search-inputs]))

(defn main [s {:keys [corpus] :as d}]
  (let [search-engine (get @corpus :search-engine :cwb)
        component (get search-inputs/components search-engine)]
    [:div [component s d]]))
