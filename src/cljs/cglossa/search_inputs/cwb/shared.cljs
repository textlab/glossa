(ns cglossa.search-inputs.cwb.shared)

(defn- search! [query-cursor]
  (.log js/console "soker"))

(defn on-key-down [event query-cursor]
  (when (= "Enter" (.-key event))
    (.preventDefault event)
    (search! query-cursor)))

(defn remove-row-btn [show? handler]
  [:button.btn.btn-danger.btn-xs {:type     "button"
                                  :title    "Remove row"
                                  :on-click #(handler)
                                  :style    {:margin-right 5
                                             :visibility   (if show?
                                                             "visible"
                                                             "hidden")}}
   [:span.glyphicon.glyphicon-remove]])
