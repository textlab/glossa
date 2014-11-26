(ns cglossa.data-import.core
  (require [clojure.string :as str]
           [datomic.api :as d]))

(def data-path "resources/data")

(defn- tsv->rows [path]
  "Takes the path to a tsv file and returns a seq of rows, where each
  row is a seq of fields from the file."
  (->> (slurp path)
       str/split-lines
       (map #(str/split % #"\t"))))

(defn- tsv->tx-data [path namespace]
  "Takes as input a tsv (tab-separated values) file with attribue names
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

(defn- create-metadata-value-maps [val-id-maps headers categories]
  (mapcat (fn [category-vals header]
            (let [category (first (filter #(= (:metadata-category/short-name %) header)
                                          categories))]
              (for [[val id] category-vals]
                {:db/id                     (d/tempid :db.part/glossa (- -1 id))
                 :metadata-value/text-value val
                 :metadata-category/_values (:db/id category)})))
          val-id-maps headers))

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
          data (rest rows)
          cols (apply map list data)
          unique-vals (map set cols)
          tids (first unique-vals)
          nrows (count tids)
          val-id-maps (map-indexed (fn [index cat-vals]
                                     (let [first-id (* index nrows)]
                                       (into {}
                                             (map (fn [val id] [val id])
                                                  cat-vals
                                                  (map #(+ % first-id) (range nrows))))))
                                   unique-vals)]
      (when-not (= (first headers) "tid")
        (throw (Exception. (str "The first column should be tid, not " (first headers) "!"))))
      (for [row data
            :let [[tid & fields] row]]
        (map (fn [header value]
               {:db/id (d/tempid :db.part/glossa)
                :metadata_value value})
             headers fields))
      (create-metadata-value-maps val-id-maps headers categories))))
