(ns cglossa.react-adapters.bootstrap
  (:require cljsjs.react-bootstrap
            reagent.core)
  (:require-macros [cglossa.react-adapters.bootstrap :refer [adapt!]]))

;; This will define a set of Vars in the current namespace, one for each of the
;; listed Bootstrap components and resulting from running reagent.core/adapt-react-class
;; on the component. The Var names will be lower-cased, for instance `button` for
;; js/ReactBootstrap.Button, so they should be referred like this in other namespaces:
;; (:require [cglossa.react-adapters.bootstrap :refer [button modal label])
(adapt! "Button"
        "ButtonToolbar"
        "Input"
        "Label"
        "Modal"
        "ModalBody"
        "ModalFooter"
        "ModalHeader"
        "ModalTitle"
        "Navbar")
