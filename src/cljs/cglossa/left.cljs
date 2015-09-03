(ns cglossa.left
  (:require [reagent.core :as r]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.select2 :refer [select2]]))

(defn metadata-list [{:keys [open-metadata-cat]} {:keys [search metadata-categories]}]
  [:div#sidebar-wrapper
   (doall
     (for [cat @metadata-categories
           :let [cat-id (:rid cat)
                 open?  (or (= @open-metadata-cat cat-id)
                            (get @search cat-id))]]
       ^{:key cat-id}
       [:div.metadata-category
        [:a {:href "#" :on-click (fn [e]
                                   (reset! open-metadata-cat (if open? nil cat-id))
                                   (.preventDefault e))}
         (:name cat)]
        (when open?
          (list
            [b/button {:bs-size "xsmall"
                       :bs-style "danger"
                       :title "Remove selection"
                       :class-name "close-cat-btn"
                       :on-click #(reset! open-metadata-cat nil)}
             [b/glyphicon {:glyph "remove"}]]
            [select2 (r/atom nil) (r/atom nil) {:placeholder "Click to select..."}
             [:div
              [:select.list {:style {:width "100%"} :multiple true}]]]))]))])
