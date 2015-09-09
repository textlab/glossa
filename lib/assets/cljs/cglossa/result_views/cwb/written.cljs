(ns cglossa.result-views.cwb.written
  (:require [clojure.string :as str]
            [cglossa.result-views.cwb.core :refer [concordance-rows]]
            [cglossa.result-views.cwb.shared :as shared]))

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

(defn- extract-fields [res]
  (let [m (re-find #"<s_id\s+(.*?)>(.*)\{\{(.+?)\}\}(.*?)</s_id>$" (:text res))]
    (let [[_ s-id pre match post] m]
      [(str/trim s-id) [pre match post]])))

(defn- main-row [result index a {:keys [corpus] :as m}]
  ^{:key (hash result)}
  [:tr
   (shared/id-column result)
   (shared/text-columns result)])

(defmethod concordance-rows :default [a m res index]
  "Returns one or more rows representing a single search result."
  (let [[s-id [pre match post]] (extract-fields res)
        res-info {:s-id       s-id
                  :pre-match  pre
                  :match      match
                  :post-match post}
        main     (main-row res-info index a m)]
    main))
