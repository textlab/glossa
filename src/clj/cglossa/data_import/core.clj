(ns cglossa.data-import.core
  (require [clojure.string :as str]
           [datomic.api :refer [tempid]]))

(defn- tsv->rows [path]
  "Takes the path to a tsv file and returns a seq of rows, where each
  row is a seq of fields from the file."
  (->> (slurp path)
       str/split-lines
       (map #(str/split % #"\t"))))

(defn tsv->tx-data [path namespace]
  "Takes as input a tsv (tab-separated values) file with attribute names
  on the first line and the actual model data on the following lines.
  Returns a Datomic transaction data seq that can be fed directly into
  datomic.api/transact."
  (let [rows (tsv->rows path)
        attr-names (->> (first rows) (map #(keyword (name namespace) %)))
        data (rest rows)]
    (with-meta
      (for [row data]
        (into {:db/id (tempid :db.part/user)}
              (filter #(seq (val %)) (zipmap attr-names row))))  ;ignore empty strings
      {:from-path path})))
