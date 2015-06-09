(ns cglossa.db
  (:require [clojure.string :as str]
            [clojure.walk :as walk]
            [clojurewerkz.ogre.core :as q])
  (:import [com.tinkerpop.blueprints.impls.orient OrientGraphFactory]
           [com.orientechnologies.orient.core.sql OCommandSQL]
           [com.orientechnologies.orient.core.db.record OIdentifiable]))

(defn get-graph
  ([]
   (get-graph true))
  ([transactional?]
   (let [factory (OrientGraphFactory. "remote:localhost/Glossa" "admin" "admin")]
     (if transactional? (.getTx factory) (.getNoTx factory)))))

(defn db-record? [o]
  (instance? OIdentifiable o))

(defn stringify-rid [rid]
  "When we ask for @rid in an SQL query, the value we get for the 'rid' property is
  actually the entire record object. This function converts it into the string
  representation of the record's @rid (e.g. 12:0)"
  (.. rid getIdentity toString))

(defn- xform-val [val]
  "Transform the values of vertex properties retrieved via SQL as needed."
  (cond
    (db-record? val) (stringify-rid val)
    (instance? Iterable val) (map xform-val val)
    :else val))

(defn vertex->map [v]
  (as->
    ;; Get all the key-value pairs for the OrientVertex
    (.getProperties v) $
    ;; Convert them to a Clojure hash map
    (into {} $)
    ;; @rid is just a temporary key for the result object, so remove it
    (dissoc $ "@rid")
    ;; Transform values as needed
    (walk/walk (fn [[k v]] [k (xform-val v)]) identity $)))

(defn sql-query
  "Takes an SQL query and optionally a map of parameters, runs it against the
  OrientDB database, and returns the query result as a seq. The params argument
  is a hash map with the following optional keys:

  * target or targets: A vertex ID, or a sequence of such IDs, to use as the target
  in the SQL query (e.g. '#12:1' or ['#12:1' '#12:2']), replacing the placeholder
  #TARGET or #TARGETS (e.g. 'select from #TARGETS').

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
   (sql-query sql {}))
  ([sql params]
   (let [graph      (get-graph)
         t          (or (:target params) (:targets params))
         targets    (if t (-> t vector flatten vec) [])
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
         results    (.. graph (command cmd) (execute sql-params))]
     (map vertex->map results))))

(defn get-corpus [code]
  (let [res (sql-query (str "SELECT @rid as corpus_rid, name as corpus_name, "
                            "$cats.@rid as cat_rids, $cats.name as cat_names "
                            "FROM Corpus "
                            "LET $cats = out('HasMetadataCategory') "
                            "WHERE code = ?")
                       {:sql-params [code]})]
    (first res)))
