(ns cglossa.models.corpora
  (:require [datomic.api :as d]
            [prone.debug :refer [debug]]
            [cglossa.models.core :refer [find-by]]))

(defn by-short-name [db short-name]
  {:status  200
   :body    (d/pull db
                    [:corpus/short-name :corpus/name
                     {:corpus/metadata-categories
                      [:metadata-category/short-name :metadata-category/name]}]
                    [:corpus/short-name short-name])
   :headers {}})
