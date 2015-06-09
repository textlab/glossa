(ns cglossa.results
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]))

(defn- top []
  [:div.span9 "No matches found"])

(defn results [a {:keys [corpus] :as m}]
  (let [search-interface (search-interface-for-corpus corpus)]
    [:div
     [top]
     [search-interface a m]]))
