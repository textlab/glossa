(ns cglossa.search-inputs
  (:require [clojure.string :as str]))

(defn cwb-search-inputs [{:keys [search-query]}]
  (let [displayed-query (-> @search-query
                            :query
                            (str/replace #"\[\(?\w+=\"(.+?)\"(?:\s+%c)?\)?\]" "$1"))]
    [:div.row-fluid
    [:form.form-inline.span12
     [:div.span10
      [:input.span12 {:ref "searchfield" :type "text" :value displayed-query}]]]]))

(def components {:cwb        cwb-search-inputs
                 :cwb-speech (fn [] [:div "CWB-SPEECHE"])})
