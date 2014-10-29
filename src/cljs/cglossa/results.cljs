(ns cglossa.results
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]))

(defn- top []
  [:div.span9 "No matches found"])

(defn main [s {:keys [corpus] :as d}]
  (let [search-interface (search-interface-for-corpus corpus)]
    [:div
     [top]
     [search-interface s d]]))
