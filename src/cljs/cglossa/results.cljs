(ns cglossa.results
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]))

(defn main [s {:keys [corpus] :as d}]
  (let [search-interface (search-interface-for-corpus corpus)]
    [:div [search-interface s d]]))
