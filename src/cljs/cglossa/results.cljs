(ns cglossa.results
  (:require [cglossa.search-views.shared :refer [search-inputs]]
            [cglossa.shared :refer [top-toolbar]]
            [cglossa.search-views.cwb.shared :refer [search!]]
            [cglossa.react-adapters.bootstrap :as b]
            [reagent.core :as r]))

(defn- results-info []
  [:div.col-sm-9 "No matches found"])

(defn- sort-button [{{sb :sort-by} :results-view :as a} m]
  (let [sort-by   @sb
        on-select (fn [event-key _ _]
                    (reset! sb (keyword event-key))
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

(defn- statistics-button [{{freq-attr :freq-attr} :results-view} m]
  (let [on-select #(reset! freq-attr (keyword %1))]
    [b/dropdownbutton {:title "Statistics"}
     [b/menuitem {:header true} "Frequencies"]
     [b/menuitem {:event-key :word, :on-select on-select} "Word forms"]
     [b/menuitem {:event-key :lemma, :on-select on-select} "Lemmas"]
     [b/menuitem {:event-key :pos, :on-select on-select} "Parts-of-speech"]]))

(defn- concordance-toolbar [a m]
  [:div.row {:style {:margin-top 15 :margin-bottom 15}}
   [:div.col-sm-12
    [b/buttontoolbar
     [sort-button a m]]]])

(defmulti concordance-table
  "Multimethod that accepts two arguments - an app state map and a
  model/domain state map - and dispatches to the correct method based
  on the value of :search-engine in the corpus map found in the
  model/domain state map. The :default case implements CWB support."
  (fn [_ {corpus :corpus}] (:search-engine @corpus)))

(defn- concordances [a m]
  [:div.container-fluid {:style {:padding-left 0 :padding-right 0}}
   [concordance-toolbar a m]
   [concordance-table a m]])

(defn results [{:keys [num-resets] :as a} m]
  [:div
   [:div.row
    [top-toolbar a]
    [results-info]]
   ^{:key @num-resets} [search-inputs a m]                  ; See comments in cglossa.start
   [b/tabbedarea {:style              {:margin-top 15}
                  :animation          false
                  :default-active-key :concordance}
    [b/tabpane {:tab "Concordance" :event-key :concordance}
     [concordances a m]]
    [b/tabpane {:tab "Statistics" :event-key :statistics}]]])
