(ns cglossa.dev
  (:require [cglossa.core :as cglossa]
            [figwheel.client :as figwheel]))

(figwheel/start {:websocket-url   "ws://localhost:3449/figwheel-ws"
                 :jsload-callback (fn [] (cglossa/main))})
