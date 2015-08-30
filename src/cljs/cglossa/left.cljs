(ns cglossa.left)

(defn metadata-list [_ {:keys [metadata-categories]}]
  [:div#sidebar-wrapper
   [:ul.sidebar-nav
    [:li ]
    [:li [:a {:href "#"} "Some text"]]]])
