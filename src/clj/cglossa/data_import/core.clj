(ns cglossa.data-import.core
  (:require [cglossa.data-import
             [corpora :as corpora]
             [metadata-categories :as cats]
             [metadata-values :as vals]]))

(defn import-corpora! [] (println (corpora/import!)))

(defn import-metadata-categories! [corpus] (println (cats/import! corpus)))

(defn import-metadata-values! [corpus] (println (vals/import! corpus)))
