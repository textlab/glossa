(ns cglossa.left
  (:require [reagent.core :as r]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.select2 :as s]))

(def auto-opening-select (with-meta s/select2 {:component-did-mount #(s/trigger-event % "open")}))

(defn metadata-list [{:keys [open-metadata-cat]} {:keys [search metadata-categories]}]
  [:div#sidebar-wrapper
   (doall
     (for [cat @metadata-categories
           :let [cat-id (:id cat)
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
            ^{:key (str "close-btn" cat-id)}
            [b/button {:bs-size    "xsmall"
                       :bs-style   "danger"
                       :title      "Remove selection"
                       :class-name "close-cat-btn"
                       :on-click   #(reset! open-metadata-cat nil)}
             [b/glyphicon {:glyph "remove"}]]
            ^{:key (str "select" cat-id)}
            [auto-opening-select (r/atom nil) (r/atom nil) {:placeholder "Click to select..."}
             [:div
              [:select.list {:style {:width "100%"} :multiple true}]]]))]))])
