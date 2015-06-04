(ns cglossa.db
  (:require [clojure.string :as str]
            [clojurewerkz.ogre.core :as q])
  (:import (com.tinkerpop.blueprints.impls.orient OrientGraphFactory)
           (com.orientechnologies.orient.core.sql OCommandSQL)))

(defn get-graph
  ([] (get-graph true))
  ([transactional?]
   (let [factory (OrientGraphFactory. "remote:localhost/Glossa" "admin" "admin")]
     (if transactional? (.getTx factory) (.getNoTx factory)))))

(defn query
  "Takes an SQL query and optionally a map of parameters, runs it against the
  OrientDB database, and returns the query result as a seq. The params argument
  is a hash map with the following optional keys:

  * targets: A vertex ID, or a sequence of such IDs, to use as the target in the
  SQL query (e.g. '#12:1' or ['#12:1' '#12:2']), replacing the placeholder #TARGET
  or #TARGETS (e.g. 'select from #TARGETS').

  * strings: Map with strings that will be interpolated into the SQL query, replacing
  placeholders with the same name preceded by an ampersand. Restricted to
  letters, numbers and underscore to avoid SQL injection. Use only in those
  cases where OrientDB does not support 'real' SQL parameters (such as in the
  specification of attribute values on edges and vertices, e.g. in()[name = &name],
  with {:name 'John'} given as the value of the strings key).

  * sql-params: parameters (positioned or named) that will replace question marks
  in the SQL query through OrientDB's normal parameterization process.

  A full example:
  (query \"select out('&out') from #TARGETS where code = ?\"
         {:targets    [\"#12:0\" \"#12:1\"]
          :sql-params [\"bokmal\"]
          :strings    {:out \"HasMetadataCategory\"}})"
  ([sql]
   (query sql {}))
  ([sql params]
   (let [graph      (get-graph)
         targets    (if (:targets params)
                      (-> (:targets params) vector flatten vec)
                      [])
         _          (doseq [target targets] (assert (re-matches #"#\d+:\d+" target)
                                                    (str "Invalid target: " target)))
         strings    (:strings params)
         _          (assert (or (nil? strings) (map? strings))
                            "String params should be provided in a map")
         _          (doseq [s (vals strings)] (assert (not (re-find #"[\W]" s))
                                                      (str "Invalid string param: " s)))
         sql-params (into-array (:sql-params params))
         sql*       (-> sql
                        (str/replace #"\&(\w+)" #(get strings (keyword (second %))))
                        (str/replace #"#TARGETS?" (str "[" (str/join ", " targets) "]")))
         cmd        (OCommandSQL. sql*)
         ]
     (seq (.. graph (command cmd) (execute sql-params))))))
