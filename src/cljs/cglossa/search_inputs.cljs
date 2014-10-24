(ns cglossa.search-inputs
  (:require [clojure.string :as str]))

(defn cwb-search-inputs [{:keys [search-query]}]
  (let [query (:query @search-query)
        displayed-query (str/replace query #"\[\(?\w+=\"(.+?)\"(?:\s+%c)?\)?\]" "$1")
        phonetic? (not= -1 (.indexOf query "phon="))]
    [:div.row-fluid
     [:form.form-inline.span12
      [:div.span10
       [:input.span12 {:type "text" :value displayed-query
                       :on-change #(swap! search-query assoc-in [:query] (aget % "target" "value"))}]
       [:label {:style {:marginTop 5}}]
       [:input {:name "phonetic" :type "checkbox"
                :style {:marginTop -3} :checked phonetic?} " Phonetic form"]]]]))

(def components {:cwb        cwb-search-inputs
                 :cwb-speech (fn [] [:div "CWB-SPEECHE"])})
