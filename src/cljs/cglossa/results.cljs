(ns cglossa.results
  (:require [cglossa.search-inputs.core :refer [search-interfaces]]))

(defn main [s {:keys [corpus] :as d}]
  (let [search-engine (get @corpus :search-engine :cwb)
        search-interface (get search-interfaces search-engine)]
    [:div [search-interface s d]]))
