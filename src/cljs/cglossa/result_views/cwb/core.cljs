(ns cglossa.result-views.cwb.core
  (:require [clojure.string :as str]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.results :refer [concordance-table]]))


(defn- monolingual-or-first-multilingual [res]
  (let [m (re-find #"<(\w+_(?:id|name))(.*?)>(.*)\{\{(.+?)\}\}(.*?)</\1>$" (:text res))]
    ;; There will only be a surrounding structural attribute if the corpus has some
    ;; kind of s-unit segmentation
    (if m
      (let [[_ _ s-id pre match post] m]
        [(str/trim s-id) [pre match post]])
      ;; Try again without the surrounding structural attribute
      (let [m (re-find #"(.*)\{\{(.+?)\}\}(.*)" (:text res))
            [_ pre match post] m]
        ["" [pre match post]]))))

(defn- non-first-multilingual [res]
  ;; Extract the IDs of all s-units (typically sentences)
  ;; and put them in front of their respective s-units.
  (let [text (str/replace res
                          #"<(\w+_id)\s*(.+?)>(.*?)</\1>"
                          "<span class=\"aligned-id\">$2</span>: $3")]
    [nil [text]]))

(defn- process-field
  "Processes a pre-match, match, or post-match field."
  [field]
  (as-> field $
        ;; Extract any speaker IDs and put them in front of their segments
        (str/replace $ #"<who_name\s*(.+?)>"
                     "<span class=\"speaker-id\">&lt;$1&gt;</span>")
        (str/replace $ #"</who_name>" "")
        (str/replace $ #"span class=" "span_class=")
        (str/split $ #"\s+")
        (map (fn [token]
               (if (re-find #"span_class=" token)
                 token                                      ; Don't touch HTML spans
                 (str/split token #"/")                     ; The slash separates CWB attributes
                 ;; TODO: Handle Opentip jQuery attributes, or use something else?
                 ))
             $)
        (str/join \space $)
        (str/replace $ #"span_class=" "span class=")))

(defn- id-column [result]
  ;; If the 'match' property is defined, we know that we have a result from a monolingual
  ;; search or the first language of a multilingual one. If that is the case, and s-id is
  ;; defined, we print it in the first column (if we have a non-first language result, we
  ;; will include it in the next column instead).
  (when (and (:match result) (:s-id result))
    [:td (:s-id result)]))

(defn- text-columns [result]
  (if (:match result)
    ;; If the 'match' value is defined, we know that we have a result from a monolingual
    ;; search or the first language of a multilingual one, and then we want pre-match, match
    ;; and post-match in separate columns.
    (list [:td {:dangerouslySetInnerHTML {:__html (:pre-match result)}}]
          [:td.match {:dangerouslySetInnerHTML {:__html (:match result)}}]
          [:td {:dangerouslySetInnerHTML {:__html (:post-match result)}}])
    ;; Otherwise, we have a result from a non-first language of a multilingual search. In that
    ;; case, CQP doesn't mark the match, so we leave the first column blank and put all of the
    ;; text in a single following column.
    (list [:td]
          [:td.aligned-text {:col-span                3
                             :dangerouslySetInnerHTML {:__html (:pre-match result)}}])
    )
  )

(defn- toggle-player [index player-type media-type
                      {:keys [player-row-index current-player-type current-media-type]}]
  (let [row-no         (when-not (and (= index @player-row-index)
                                      (= player-type @current-player-type)
                                      (= media-type @current-media-type))
                         index)
        new-media-type (when row-no
                         media-type)]
    (reset! player-row-index row-no)
    (reset! current-player-type player-type)
    (reset! current-media-type media-type)))

(defn- main-row [result index a {:keys [corpus] :as m}]
  (let [sound? (:has-sound corpus)
        video? (:has-video corpus)]
    ^{:key (str "main-" (:s-id result))}
    [:tr
     (if (or sound? video?)
       [:td.span1
        (when video?
          [b/button {:bs-size  "xsmall" :title "Show video" :style {:width "100%" :margin-bottom 3}
                     :on-click #(toggle-player index "jplayer" "video" a)}
           [b/glyphicon {:glyph "film"}]])
        (when sound?
          [b/button {:bs-size  "xsmall" :title "Play audio" :style {:width "100%"}
                     :on-click #(toggle-player index "jplayer" "audio" a)}
           [b/glyphicon {:glyph "volume-up"}]]
          [b/button {:bs-size  "xsmall" :title "Show waveform" :style {:width "100%"}
                     :on-click #(toggle-player index "wfplayer" "audio" a)}
           [:img {:src "img/waveform.png"}]])])
     (id-column result)
     (text-columns result)]))

(defn- extra-row [result attr {:keys [corpus]}]
  (let [sound?       (:has-sound corpus)
        video?       (:has-video corpus)
        match        (first (filter (fn [_ v] (:is-match v))
                                    (get-in result [:media-obj :divs :annotation])))
        row-contents (str/join " " (for [[_ v] (:line match)]
                                     (get v attr)))]
    [:tr
     (when (:s-id result)
       [:td])
     (when (or sound? video?)
       [:td.span1])
     [:td {:col-span 3}
      row-contents]]))

(defn- result-rows [{:keys [player-row-index current-player-type current-media-type] :as a}
                    {:keys [corpus] :as m}
                    res index]
  "Returns one or more rows representing a single search result."
  (let [[s-id fields] (if (re-find #"\{\{" (:text res))
                        ;; The result contains {{, which  is the left delimiter of a
                        ;; match, meaning that this is a result from a monolingual
                        ;; search or from the first language of a multilingual search.
                        (monolingual-or-first-multilingual res)
                        ;; No {{ was found, so this is a result from a non-first
                        ;; language in a multilingual search.
                        (non-first-multilingual res))
        [pre match post] (map process-field fields)
        res-info  {:s-id       s-id
                   :pre-match  pre
                   :match      match
                   :post-match post}
        main      (main-row res-info index a m)
        extras    (for [attr []]                            ; TODO: Handle extra attributes
                    (extra-row res-info attr m))
        media-row (if (= index player-row-index)
                    (condp = current-player-type
                      "jplayer"
                      [:tr
                       [:td {:col-span 10}
                        [:Jplayer {:media-obj  (:media-obj res-info)
                                   :media-type current-media-type
                                   :ctx_lines  (:initial-context-size corpus 1)}]]]

                      "wfplayer"
                      [:tr
                       [:td {:col-span 10}
                        [:WFplayer {:media-obj (:media-obj res-info)}]]]))]
    #_(flatten [main extras media-row])
    main))

(defmethod concordance-table :default [{:keys [search-results] :as a} m]
  (let [results @search-results]
    [:div.row>div.col-sm-12 {:style {:height 320 :overflow "auto"}}
     [b/table {:striped true :bordered true}
      [:tbody
       (map (partial result-rows a m)
            results
            (range (count results)))]]]))
