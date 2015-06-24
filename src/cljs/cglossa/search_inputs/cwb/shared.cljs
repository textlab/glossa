(ns cglossa.search-inputs.cwb.shared)

(defn- search! [wrapped-query]
  (.log js/console "soker"))

(defn on-key-down [event wrapped-query]
  (when (= "Enter" (.-key event))
    (.preventDefault event)
    (search! wrapped-query)))

(defn remove-row-btn [show? handler]
  [:button.btn.btn-danger.btn-xs {:type     "button"
                                  :title    "Remove row"
                                  :on-click #(handler)
                                  :style    {:margin-right 5
                                             :padding-top  3
                                             :visibility   (if show?
                                                             "visible"
                                                             "hidden")}}
   [:span.glyphicon.glyphicon-remove]])
