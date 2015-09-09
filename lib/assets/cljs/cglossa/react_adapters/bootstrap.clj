(ns cglossa.react-adapters.bootstrap
  (:require [clojure.string :as str]))

;; This needs to be a macro in order for it to access the ReactBootstrap
;; JS object in the js namespace (or is there another way?). It will define a set of Vars
;; in the namespace where the macro is called, one for each of the listed Bootstrap
;; components and resulting from running reagent.core/adapt-react-class
;; on the component. The Var names will be lower-cased, for instance `button` for
;; js/ReactBootstrap.Button.
(defmacro adapt! [& components]
  `(do ~@(for [c components]
           `(def ~(symbol (str/lower-case c))
              (reagent.core/adapt-react-class ~(symbol "js" (str "ReactBootstrap." c)))))))
