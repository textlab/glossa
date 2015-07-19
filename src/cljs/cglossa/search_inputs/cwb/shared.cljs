(ns cglossa.search-inputs.cwb.shared)

(defn- search! [wrapped-query]
  (.log js/console "soker"))

(defn on-key-down [event wrapped-query]
  (when (= "Enter" (.-key event))
    (.preventDefault event)
    (search! wrapped-query)))

(defn remove-row-btn [show? wrapped-query]
  [:button.btn.btn-danger.btn-xs {:type     "button"
                                  :title    "Remove row"
                                  :on-click #(reset! wrapped-query nil)
                                  :style    {:margin-right 5
                                             :padding-top  3
                                             :visibility   (if show?
                                                             "visible"
                                                             "hidden")}}
   [:span.glyphicon.glyphicon-remove]])

(defn- on-headword-search-changed [event wrapped-query]
  (swap! wrapped-query assoc :headword-search (.-target.checked event)))

(defn headword-search-checkbox [wrapped-query margin-left]
  [:label {:style {:margin-left margin-left}}
   [:input {:type      "checkbox"
            :value     "1"
            :checked   (:headword-search @wrapped-query)
            :on-change #(on-headword-search-changed % wrapped-query)
            :id        "headword_search"
            :name      "headword_search"} " Headword search"]])
