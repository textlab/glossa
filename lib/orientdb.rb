require 'java'
require_relative 'commons-configuration-1.10.jar'
require_relative 'orientdb/blueprints-core-2.6.0.jar'
require_relative 'orientdb/concurrentlinkedhashmap-lru-1.4.1.jar'
require_relative 'orientdb/jna-4.0.0.jar'
require_relative 'orientdb/jna-platform-4.0.0.jar'
require_relative 'orientdb/orientdb-client-2.1.0.jar'
require_relative 'orientdb/orientdb-core-2.1.0.jar'
require_relative 'orientdb/orientdb-enterprise-2.1.0.jar'
require_relative 'orientdb/orientdb-graphdb-2.1.0.jar'
java_import com.tinkerpop.blueprints.impls.orient.OrientGraphFactory
java_import com.orientechnologies.orient.core.db.record.OIdentifiable
java_import com.orientechnologies.orient.core.sql.OCommandSQL

module OrientDb
  def get_graph(transactional = true)
    f = OrientGraphFactory.new('remote:localhost/Glossa', 'admin', 'admin')
    if transactional
      f.getTx
    else
      f.getNoTx
    end
  end

  def db_record?(o)
    o.java_kind_of?(OIdentifiable)
  end

  def valid_rid?(rid)
    rid =~ /^#\d+:\d+$/
  end

  # Returns the ID of record as a string.
  def stringify_rid(record)
    record.getIdentity.toString
  end

  # Transform the values of vertex properties retrieved via SQL as needed.
  def xform_val(val)
    if db_record?(val)
      # When we ask for @rid in an SQL query, the value we get for the 'rid'
      # property is actually the entire record object. Convert it into
      # the string representation of the record's @rid (e.g. 12:0).
      stringify_rid(val)
    elsif val.respond_to?(:map)
      val.map { |v| xform_val(v) }
    else
      val
    end
  end

  def vertex_to_hash(vertex)
    res = vertex.properties.reduce({}) do |h, (k, v)|
      key = k.sub(/^@/, '')
      h[key] = xform_val(v)
      h
    end
    res.symbolize_keys
  end

  def run_sql(sql, sql_params=[])
    graph = get_graph
    cmd = OCommandSQL.new(sql)
    graph.command(cmd).execute(sql_params.to_java)
  end

  # Takes an SQL query and optionally a map of parameters, runs it against the
  # OrientDB database, and returns the query result as an array of hashes.
  # The params argument is a hash with the following optional keys:

  # * target or targets: A vertex ID, or an array of such IDs, to use as the target
  # in the SQL query (e.g. '#12:1' or ['#12:1' '#12:2']), replacing the placeholder
  # #TARGET or #TARGETS (e.g. 'select from #TARGETS').

  # * strings: Hash with strings that will be interpolated into the SQL query, replacing
  # placeholders with the same name preceded by an ampersand. Restricted to
  # letters, numbers and underscore to avoid SQL injection. Use only in those
  # cases where OrientDB does not support 'real' SQL parameters (such as in the
  # specification of attribute values on edges and vertices, e.g. in()[name = &name],
  # with {:name 'John'} given as the value of the strings key).

  # * sql_params: array of parameters (positioned or named) that will replace question marks
  # in the SQL query through OrientDB's normal parameterization process.

  # A full example:
  # sql_query("select out('&out') from #TARGETS where code = ?",
  #            {targets:    ["#12:0", "#12:1"],
  #             sql_params: ["bokmal"],
  #             strings:    {out: "HasMetadataCategory"}})
  def sql_query(sql, params={})
    t = params[:target] || params[:targets]
    targets = t ? [t].flatten : []
    targets.each { |target| raise("Invalid target: " + target) unless valid_rid?(target) }

    strings = params[:strings]
    unless strings.nil?
      raise("String params should be provided in a hash") unless strings.is_a?(Hash)
      strings.values.each { |s| raise("Invalid string param: " + s) if s =~ /\W/ }
    end

    sql_params = params[:sql_params]
    sql_ = sql.gsub(/&(\w+)/) { strings[$1.to_sym] }
      .gsub(/#TARGETS?/) { |m| "[#{targets.join(", ")}]" }
    results = run_sql(sql_, sql_params)
    results.map { |r| vertex_to_hash(r) }
  end

  def vertex_name(name, code)
    name || code.humanize
  end

  # Runs the given SQL (with optional params; see `sql_query`) and wraps the
  # first returned object in the model class, which should be a class derived
  # from OpenStruct.
  def one(model, sql, params={})
    model.new(sql_query(sql, params).first)
  end

  # Runs the given SQL (with optional params; see `sql_query`), wraps each
  # returned object in the model class, which should be a class derived
  # from OpenStruct, and returns an array of those models.
  def many(model, sql, params={})
    sql_query(sql, params).each { |h| model.new(h) }
  end

end
