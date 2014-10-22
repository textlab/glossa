(ns cglossa.centre)

(defn top [{:keys [showing-results]} d]
  [:div.row-fluid
   [:div.span3.top-toolbar
    [:button#new-search-button.btn.btn-mini.btn-primary {:title "Reset form"} "Reset form"]]
   (if @showing-results
     [:div.span9 "No matches found"]
     [:div.span9 "Starter"])])
