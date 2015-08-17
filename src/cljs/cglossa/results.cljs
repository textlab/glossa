(ns cglossa.results
  (:require [cglossa.search-views.shared :refer [search-inputs]]
            [cglossa.shared :refer [top-toolbar]]
            [cglossa.search-views.cwb.shared :refer [search!]]
            [cglossa.react-adapters.bootstrap :as b]
            [reagent.core :as r]))

(defn- results-info []
  [:div.col-sm-9 "No matches found"])

(defn- sort-button [{:keys [sort-results-by] :as a} m]
  (let [sort-by   @sort-results-by
        on-select (fn [event-key _ _]
                    (reset! sort-results-by (keyword event-key))
                    (search! a m))]
    [b/dropdownbutton {:title "Sort" :bs-size "small"}
     [b/menuitem {:event-key :position, :on-select on-select}
      (when (= sort-by :position) [b/glyphicon {:glyph "ok"}]) "  By corpus position"]
     [b/menuitem {:event-key :match, :on-select on-select}
      (when (= sort-by :match) [b/glyphicon {:glyph "ok"}]) "  By match"]
     [b/menuitem {:event-key :left, :on-select on-select}
      (when (= sort-by :left) [b/glyphicon {:glyph "ok"}]) "  By left context"]
     [b/menuitem {:event-key :right, :on-select on-select}
      (when (= sort-by :right) [b/glyphicon {:glyph "ok"}]) "  By right context"]]))

(defn- statistics-button [{:keys [freq-attr]} m]
  (let [on-select #(reset! freq-attr (keyword %1))]
    [b/dropdownbutton {:title "Statistics"}
     [b/menuitem {:header true} "Frequencies"]
     [b/menuitem {:event-key :word, :on-select on-select} "Word forms"]
     [b/menuitem {:event-key :lemma, :on-select on-select} "Lemmas"]
     [b/menuitem {:event-key :pos, :on-select on-select} "Parts-of-speech"]]))

(defn- results-toolbar [a m]
  [:div.row {:style {:margin-top 15}}
   [:div.col-sm-12
    [b/buttontoolbar
     [sort-button a m]
     [statistics-button a m]]]])

(defn- freq-modal [{:keys [freq-attr] :as a} m]
  (let [attr @freq-attr
        on-hide #(reset! freq-attr nil)]
    [b/modal {:show    (some? attr)
              :on-hide on-hide}
     [b/modalheader {:close-button true}
      [b/modaltitle "Frequencies"]]
     [b/modalbody (when attr
                    (name attr))]
     [b/modalfooter
      [b/button {:on-click on-hide} "Close"]]]))

(defn results [{:keys [num-resets] :as a} m]
  [:div
   [:div.row
    [top-toolbar a]
    [results-info]]
   ^{:key @num-resets} [search-inputs a m]                  ; See comments in cglossa.start
   [results-toolbar a m]
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
      #_[geo-distribution-map-window {:data geo-distribution}]]])
