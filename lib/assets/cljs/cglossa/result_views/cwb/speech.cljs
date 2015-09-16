(ns cglossa.result-views.cwb.speech
  (:require [clojure.string :as str]
            [cglossa.react-adapters.bootstrap :as b]
            [cglossa.result-views.cwb.core :refer [concordance-rows]]
            [cglossa.result-views.cwb.shared :as shared]))

(defn- toggle-player [index player-type media-type
                      {{:keys [player-row-index current-player-type current-media-type]} :media}]
  (let [row-no         (when-not (and (= index @player-row-index)
                                      (= player-type @current-player-type)
                                      (= media-type @current-media-type))
                         index)
        new-media-type (when row-no
                         media-type)]
    (reset! player-row-index row-no)
    (reset! current-player-type player-type)
    (reset! current-media-type media-type)))

(defn- extract-fields [res]
  (let [m (re-find #"<who_name\s+(.*?)>(.*)\{\{(.+?)\}\}(.*?)</who_name>$" (:text res))]
    (let [[_ s-id pre match post] m]
      [(str/trim s-id) [pre match post]])))

(defn- main-row [result index a {:keys [corpus] :as m}]
  (let [corpus* @corpus
        sound?  (:has-sound corpus*)
        video?  (:has-video corpus*)]
    ^{:key (hash result)}
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
     (shared/id-column result)
     (shared/text-columns result)]))

(defn- extra-row [result attr {:keys [corpus]}]
  (let [corpus*      @corpus
        sound?       (:has-sound corpus*)
        video?       (:has-video corpus*)
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

(defn- process-field [field]
  "Processes a pre-match, match, or post-match field."
  (as-> field $
        ;; Extract any speaker IDs and put them in front of their segments
        (str/replace $ #"<who_name\s*(.+?)>"
                     "<span class=\"speaker-id\">&lt;$1&gt;</span>")
        (str/replace $ #"</who_name>" "")
        (str/replace $ #"span class=" "span_class=")
        (str/split $ #"\s+")
        ;; TODO: Handle Opentip jQuery attributes, or use something else?
        #_(map (fn [token]
                 (if (re-find #"span_class=" token)
                   token                                    ; Don't touch HTML spans
                   (str/split token #"/")                   ; The slash separates CWB attributes
                   ))
               $)
        (str/join \space $)
        (str/replace $ #"span_class=" "span class=")))

(defmethod concordance-rows :speech_cwb
  [{:keys [player-row-index current-player-type current-media-type] :as a}
   {:keys [corpus] :as m} res index]
  "Returns one or more rows representing a single search result."
  (let [[s-id fields] (extract-fields res)
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
                                   :ctx_lines  (:initial-context-size @corpus 1)}]]]

                      "wfplayer"
                      [:tr
                       [:td {:col-span 10}
                        [:WFplayer {:media-obj (:media-obj res-info)}]]]))]
    #_(flatten [main extras media-row])
    main))
