(ns cglossa.start
  (:require [cglossa.search-views.shared :refer [search-inputs]]
            [cglossa.react-adapters.bootstrap :as b]))

(defn- top [{:keys [search-queries num-resets]}]
  [:div.row>div.col-md-3
   [b/buttontoolbar {:style {:margin-bottom 20}}
    [b/button {:bs-style "primary"
               :bs-size  "xsmall"
               :title    "Reset form"
               :on-click (fn []
                           (reset! search-queries [{:query ""}])
                           (swap! num-resets inc))}         ; see comments in the start component
     "Reset form"]]])

(defn- corpus-info [_ {:keys [corpus]}]
  ;; Remove the background image (gradient, really) set by bootstrap-theme,
  ;; since the unthemed well is actually nicer.
  [:div.row.corpus-info>div.col-md-12
   [:div.well {:style {:background-image "url()"}}
    [:h2
     (:name @corpus)
     (when-let [logo (:logo @corpus)]
       [:img.corpus-logo {:src (str "img/" logo)}])]]])

(defn start [{:keys [num-resets] :as a} m]
  [:div
   [top a]
   [corpus-info a m]
   ;; Using num-resets as key is a hackish way to force reagent to
   ;; re-mount the currently selected search inputs each time the form
   ;; is reset and num-resets incremented. Since the text inputs are uncontrolled
   ;; (to prevent the cursor from jumping to the end when we edit them)
   ;; we need to re-mount them in order for them to set the new, blank
   ;; query as their value.
   ^{:key @num-resets} [search-inputs a m]])
