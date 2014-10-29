(ns cglossa.search-inputs.core
  (:require [cglossa.search-inputs.cwb :as cwb]))

(def components {:cwb        cwb/search-inputs
                 :cwb-speech (fn [] [:div "CWB-SPEECH"])})
