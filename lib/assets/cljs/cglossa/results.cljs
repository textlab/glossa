(ns cglossa.results
  (:require-macros [cljs.core.async.macros :refer [go]])
  (:require [reagent.core :as r]
            [cljs-http.client :as http]
            [cljs.core.async :refer [<!]]
            [cglossa.search-views.shared :refer [search-inputs]]
            [cglossa.shared :refer [top-toolbar]]
            [cglossa.search-views.cwb.shared :refer [page-size search!]]
            [cglossa.react-adapters.bootstrap :as b]))

(defn- results-info [{{total :total} :results-view searching? :searching?}]
  (let [total*      @total
        searching?* @searching?]
    [:div.col-sm-5
     (if (pos? total*)
       (if searching?*
         (str "Showing the first " total* " matches; searching for more...")
         (str "Found " total* " matches"))
       (when searching?* "Searching..."))]))

(defn- sort-button [{{sb :sort-by total :total} :results-view searching? :searching? :as a} m]
  (let [sort-by   @sb
        on-select (fn [event-key _ _]
                    (reset! sb (keyword event-key))
                    (search! a m))]
    [b/dropdownbutton {:title    "Sort"
                       :bs-size  "small"
                       :disabled (or @searching?
                                     (zero? @total))
                       :style    {:margin-bottom 10}}
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

(defn- fetch-results! [corpus search-id current-results page-no new-page-no sort-by]
  (go
    (let [url        (str "search_engines/" (:search-engine @corpus "cwb") "_searches/"
                          (subs search-id 1) "/results")
          start      (* (dec new-page-no) page-size)
          end        (+ start (dec page-size))
          results-ch (http/get url {:query-params {:start     start
                                                   :end       end
                                                   :sort-by   (name @sort-by)}})
          {:keys [status success] {{results :result} :search_results} :body} (<! results-ch)]
      (if-not success
        (.log js/console status)
        (do
          (swap! current-results assoc new-page-no results)
          (reset! page-no new-page-no))))))

(defn- pagination [{{:keys [results total page-no paginator-page-no sort-by]} :results-view}
                   {:keys [corpus search]}]
  (let [last-page-no #(inc (quot @total page-size))
        set-page     (fn [e n]
                       (.preventDefault e)
                       (let [new-page-no (js/parseInt n)]
                         (when (<= 1 new-page-no (last-page-no))
                           ;; Set the value of the page number shown in the paginator; it may
                           ;; differ from the page shown in the result table until we have
                           ;; actually fetched the data from the server
                           (reset! paginator-page-no new-page-no)
                           (if (get @results new-page-no)
                             ;; The selected result page has already been fetched from the
                             ;; server and can be shown in the result table immediately
                             (reset! page-no new-page-no)
                             ;; Otherwise, we need to fetch the results from the server
                             ;; before setting page-no in the top-level app-data structure
                             (fetch-results! corpus (:rid @search) results
                                             page-no new-page-no sort-by)))))]
    (when (> @total page-size)
      [:div.pull-right
       [:nav
        [:ul.pagination.pagination-sm
         [:li {:class-name (when (= @paginator-page-no 1)
                             "disabled")}
          [:a {:href       "#"
               :aria-label "First"
               :title      "First"
               :on-click   #(set-page % 1)}
           [:span {:aria-hidden "true"} "«"]]]
         [:li {:class-name (when (= @paginator-page-no 1)
                             "disabled")}
          [:a {:href       "#"
               :aria-label "Previous"
               :title      "Previous"
               :on-click   #(set-page % (dec @paginator-page-no))}
           [:span {:aria-hidden "true"} "‹"]]]
         [:li
          [:select.form-control.input-sm {:style     {:direction        "rtl"
                                                      :width            60
                                                      :float            "left"
                                                      :border-radius    0
                                                      :height           27
                                                      :line-height      27
                                                      :border           0
                                                      :outline          "1px solid #ddd"
                                                      :margin-top       1
                                                      :background-color "white"}
                                          :value     @paginator-page-no
                                          :on-change #(set-page % (.-target.value %))}
           (for [i (range 1 (inc (last-page-no)))]
             ^{:key i} [:option {:value i} i])]]
         [:li {:class-name (when (= @paginator-page-no (last-page-no))
                             "disabled")}
          [:a {:href       "#"
               :aria-label "Next"
               :title      "Next"
               :on-click   #(set-page % (inc @paginator-page-no))}
           [:span {:aria-hidden "true"} "›"]]]
         [:li {:class-name (when (= @paginator-page-no (last-page-no))
                             "disabled")}
          [:a {:href       "#"
               :aria-label "Last"
               :title      "Last"
               :on-click   #(set-page % (last-page-no))}
           [:span {:aria-hidden "true"} "»"]]]]]])))

(defn- concordance-toolbar [a m]
  [:div.row {:style {:margin-top 15}}
   [:div.col-sm-12
    [b/buttontoolbar
     [sort-button a m]
     [pagination a m]]]])

(defmulti concordance-table
  "Multimethod that accepts two arguments - an app state map and a
  model/domain state map - and dispatches to the correct method based
  on the value of :search-engine in the corpus map found in the
  model/domain state map. The :default case implements CWB support."
  (fn [_ {corpus :corpus}] (:search-engine @corpus)))

(defn- concordances [a m]
  [:div.container-fluid {:style {:padding-left 0 :padding-right 0}}
   [concordance-toolbar a m]
   [concordance-table a m]
   [:div.row
    [:div.col-sm-12
     [pagination a]]]])

(defn results [{:keys [num-resets] :as a} m]
  [:div
   [:div.row
    [top-toolbar a]
    [results-info a]]
   ^{:key @num-resets} [search-inputs a m]                  ; See comments in cglossa.start
   [b/tabbedarea {:style              {:margin-top 15}
                  :animation          false
                  :default-active-key :concordance}
    [b/tabpane {:tab "Concordance" :event-key :concordance}
     [concordances a m]]
    [b/tabpane {:tab "Statistics" :event-key :statistics}]]])
