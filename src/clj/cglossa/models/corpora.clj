(ns cglossa.models.corpora
  (:require [datomic.api :as d]
            [prone.debug :refer [debug]]
            [cglossa.models.core :refer [find-by]]))

(defn by-short-name [{{short-name :short-name} :params :as req}]
  {:status 200
   :body (find-by :corpus/short-name short-name)
   :headers {}})
