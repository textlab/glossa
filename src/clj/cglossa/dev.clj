(ns cglossa.dev
  (:require [environ.core :refer [env]]
            [net.cgrand.enlive-html :refer [set-attr prepend append html]]))

(def is-dev? (env :is-dev))

(def inject-devmode-html
  (comp
    (set-attr :class "is-dev")
    (append  (html [:script {:type "text/javascript"} "goog.require('cglossa.dev')"]))))
