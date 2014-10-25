(ns cglossa.search-inputs
  (:require [clojure.string :as str]))

(defn- convert-to-cqp [value phonetic?]
  (let [attr (if phonetic? "phon" "word")
        chinese-chars-range "[\u4E00-\u9FFF\u3400-\u4DFF\uF900-\uFAFF]"
        ; Surround every Chinese character by space when constructing a cqp query,
        ; to treat it as if it was an individual word:
        value (str/replace value (re-pattern (str "(" chinese-chars-range ")")) " $1 ")]
    (->> (str/split value #"\s")
         (map #(if (= % "")
                ""
                (str "[" attr "=\"" % "\" %c]")))
         (str/join " "))))

(defn- handle-text-changed [event search-query phonetic?]
  (let [value (aget event "target" "value")
        query (if (= value "")
                ""
                (convert-to-cqp value phonetic?))]
    (swap! search-query assoc-in [:query] query)))

(defn- handle-phonetic-changed [event search-query]
  (let [query (:query @search-query)
        checked? (aget event "target" "checked")
        query (if checked?
                (str/replace query "word=" "phon=")
                (str/replace query "phon=" "word="))]
    (swap! search-query assoc-in [:query] query)))

(defn cwb-search-inputs [{:keys [search-query]}]
  (let [query (:query @search-query)
        displayed-query (str/replace query #"\[\(?\w+=\"(.+?)\"(?:\s+%c)?\)?\]" "$1")
        phonetic? (not= -1 (.indexOf query "phon="))]
    [:div.row-fluid
     [:form.form-inline.span12
      [:div.span10
       [:input.span12 {:type "text" :value displayed-query
                       :on-change #(handle-text-changed % search-query phonetic?)}]
       [:label {:style {:marginTop 5}}]
       [:input {:name "phonetic" :type "checkbox"
                :style {:marginTop -3} :checked phonetic?
                :on-change #(handle-phonetic-changed % search-query)} " Phonetic form"]]]]))

(def components {:cwb        cwb-search-inputs
                 :cwb-speech (fn [] [:div "CWB-SPEECHE"])})
