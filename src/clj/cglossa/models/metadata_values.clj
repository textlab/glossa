(ns cglossa.models.metadata-values
  (:require [datomic.api :as d]))

(defn index [db category-id]
  {:status 200
   :body (d/pull db [:metadata-category/values] 17592186045423)
   :headers {}})
