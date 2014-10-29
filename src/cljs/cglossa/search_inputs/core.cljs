(ns cglossa.search-inputs.core
  (:require [cglossa.search-inputs.cwb :as cwb]))

; Maps search engine to search interface component. Looks like we need this
; since CLJS doesn't support ns-resolve.
(def search-interfaces {:cwb cwb/search-inputs})

(defn search-interface-for-corpus [corpus]
  (let [search-engine (get @corpus :search-engine :cwb)]
    (get search-interfaces search-engine)))
