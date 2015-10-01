(ns cglossa.select2
  (:require [reagent.core :as r]
            [cljsjs.jquery]
            js-select2))

(defn- unpacked
  "Dereferences the object if it implements the IDeref protocol;
  otherwise returns the object itself."
  [obj]
  (if (satisfies? IDeref obj) @obj obj))

(defn- get-select-el [component]
  (js/$ "select.list" (r/dom-node component)))

(defn trigger-event [component event-name]
  (.select2 (get-select-el component) event-name))

(defn select2 [data value options render-body]
  "Creates a select box using the select2 jQuery plugin. options should
  be a hash map that will be converted to JS and provided as options to the
  plugin, while render-body should be a hiccup form that will be returned
  from the render function. The hiccup form should contain a select element
  with the CSS class 'list'; this is where the select2 box will be instantiated."
  (let [sort-data     #(clj->js (sort-by (fn [e] (aget e "text")) %))
        prev-data     (atom [])
        prev-value    (atom nil)

        ;; Sets the entries in the list equal to the contents of the 'data'
        ;; ratom that was passed to the main function
        set-data!     (fn [sel]
                        (let [data* (unpacked data)]
                          (if (not= data* @prev-data)
                            (do
                              (reset! prev-data data*)
                              (let [entries (->> data*
                                                 (map (fn [[id name]] {:id id :text name})))]
                                (.select2 sel (clj->js
                                                (merge options
                                                       {:data   entries
                                                        :sorter sort-data})))))
                            sel)))

        ;; Sets the selection of the select box to be equal to the contents of
        ;; the 'value' ratom that was passed to the main function
        set-value!    (fn [sel]
                        (if (not= @value @prev-value)
                          (do
                            (reset! prev-value @value)
                            (doto sel
                              (.val (clj->js @value))
                              (.trigger "change")))
                          sel))]
    (r/create-class
      {:component-did-mount
       (fn [c]
         (-> (.select2 (get-select-el c) (clj->js options))
             (.on "change" (fn [_]
                             ;; Show the spinner overlay on the result table
                             (.removeClass (js/$ ".spinner-overlay") "hidden")
                             ;; Update the list selection on the next requestAnimationFrame.
                             ;; Otherwise the display of the spinner overlay will be
                             ;; batched together with this and won't be visible while we
                             ;; are querying for the new database value for the result
                             ;; table.
                             (this-as elem
                               (r/next-tick (fn []
                                              (let [old-val @value
                                                    new-val (js->clj (.val (js/$ elem)))]
                                                (when (not= old-val new-val)
                                                  (reset! value new-val))))))))
             (set-data!)
             (set-value!)))

       :component-will-unmount
       (fn [c] (.select2 (get-select-el c) "destroy"))

       :component-did-update
       (fn [c _] (-> (get-select-el c) (set-value!) (set-data!)))

       :render
       (fn [_]
         ;; Even though we don't actually render the contents of these
         ;; ratoms, we still need to deref them here in order for component-did-update
         ;; (where we do in fact use the ratoms) to be called. Dereferencing them only in
         ;; component-did-update is not sufficient. Note that 'data' may be either a ratom
         ;; or an ordinary seq, so we need to check if it is deref-able.
         (when (satisfies? IDeref data) (deref data))
         (deref value)
         render-body)})))
