(ns cglossa.results
  (:require [cglossa.search-inputs.core :refer [search-interface-for-corpus]]
            cljsjs.react-bootstrap
            [cglossa.react-adapters.bootstrap :as b]
            [reagent.core :as r]))

(defn- top []
  [:div.col-md-9 "No matches found"])

(defn- freq-modal [{:keys [showing-freqs?] :as a} m]
  [b/modal {:show    @showing-freqs?
            :on-hide #(.log js/console "lukker")}
   [b/modalheader {:close-button true}
    [b/modaltitle "Frequencies"]]
   [b/modalbody "Some text will be here"]
   [b/modalfooter
    [b/button "Close"]]])

(defn results [a {:keys [corpus] :as m}]
  (let [search-interface (search-interface-for-corpus corpus)]
    [:div
     [top]
     [search-interface a m]
     #_[results-toolbar]
     #_[results-table]
     [freq-modal a m]
     #_[dialog {:data-frequency-dialog true :title "Frequencies"}
        [:table.table.table-striped.table-condensed
         [:thead
          [:td "Form"]] [:td "Frequency"]
         [:tbody
          (frequency-list)]]]
     #_[dialog {:data-distr-map   true
                :extra-class-name "distr-map"
                :title            "Geographical distribution of results"}
        #_[geo-distribution-map-window {:data geo-distribution}]]]))
