(ns cglossa.data-import.core
  (:require [clojure.string :as str]
           [datomic.api :as d]))

(def data-path "resources/data")

(defn- tsv->rows [path]
  "Takes the path to a tsv file and returns a seq of rows, where each
  row is a seq of fields from the file."
  (->> (slurp path)
       str/split-lines
       (map #(str/split % #"\t"))))

(defn- tsv->tx-data [path namespace]
  "Takes as input a tsv (tab-separated values) file with attribute names
  on the first line and the actual model data on the following lines.
  Returns a Datomic transaction data seq that can be fed directly into
  datomic.api/transact."
  (let [rows (tsv->rows path)
        attr-names (->> (first rows) (map #(keyword (name namespace) %)))
        data (rest rows)]
    (with-meta
      (for [row data]
        (into {:db/id (d/tempid :db.part/glossa)}
              (filter #(seq (val %)) (zipmap attr-names row))))  ;ignore empty strings
      {:from-path path})))

(defn- connect-metadata-values-to-cats [value-id-maps headers categories]
  "Creates Datomic transaction maps for metadata values and connects them
  to their metadata categories"
  (mapcat (fn [category-values header]
            (let [category (first (filter #(= (:metadata-category/short-name %) header)
                                          categories))
                  cat-id (:db/id category)]
              (for [[value id] category-values]
                {:db/id                     (d/tempid :db.part/glossa (- -1 id))
                 :metadata-value/text-value value
                 :metadata-category/_values cat-id})))
          value-id-maps headers))

(defn- connect-metadata-values-to-tids [value-id-maps]
  "Connects each (non-tid) metadata value to its corresponding tid (text ID) value.
  Since each tid represents a corpus text, this amounts to connecting the metadata
  values to their respective texts.")

(defn import-corpora []
  (tsv->tx-data (str data-path "/corpora.tsv") :corpus))

(defn import-metadata-categories [corpus-short-name]
  (let [path (str data-path "/metadata_categories/" corpus-short-name ".tsv")]
    (->> (tsv->tx-data path :metadata-category)
         ; associate the metadata with the appropriate corpus by adding
         ; an attribute with a corpus lookup ref to each metadata category
         (map #(into % {:corpus/_metadata-categories [:corpus/short-name corpus-short-name]})))))

(defn import-metadata-values [corpus-short-name db]
  (let [path (str data-path "/metadata_values/" corpus-short-name ".tsv")]
    (let [categories (:corpus/metadata-categories
                      (d/pull db
                              '[{:corpus/metadata-categories
                                 [:db/id :metadata-category/short-name]}]
                              [:corpus/short-name corpus-short-name]))
          rows (tsv->rows path)
          headers (first rows)
          value-rows (rest rows)
          cols (apply map list value-rows)
          unique-values (map set cols)
          tids (first unique-values)
          nrows (count tids)
          value-id-maps (map-indexed (fn [index cat-values]
                                     (let [first-id (* index nrows)]
                                       (into {}
                                             (map (fn [value id] [value id])
                                                  cat-values
                                                  (map #(+ % first-id) (range nrows))))))
                                   unique-values)]
      (when-not (= (first headers) "tid")
        (throw (Exception. (str "The first column should be tid, not " (first headers) "!"))))
      (connect-metadata-values-to-cats value-id-maps headers categories))))
