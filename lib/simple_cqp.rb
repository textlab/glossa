# An interface to CWB using the CQP shell command.
#
# It communicates with CQP via files. This makes running CQP
# queries reasonably fast and any charset problems becomes a
# matter of reading and writing files correctly.

# TODO avoid dumping really large queries by checking size

class SimpleCQP
  attr_accessor :query_file, :result_file, :error_file
  
  # The initializer may run a CQP query to store a dump
  # of the query results.
  # Reinitialize with the id set in the context object
  # to reuse the dumped query.
  #
  # The initializer is passed a CQPQueryContext instance that must
  # contain all the settings needed to run the query. The registry
  # must be set for all CQP operations. A corpus query must also
  # have the query_string and corpus set to be able to run.
  #
  # query_context - A CQPQueryContext instance with the necessary
  #                 CQP and query settings.
  #
  # Options:
  # :cqp_path - Path to CWB/CQP binaries.
  def initialize(query_context, opts={})
    @cqp_path = opts.has_key?(:cqp_path) ? opts[:cqp_path] + '/' : ""
    # problems sourcing bin names from initializers (glossa.rb)
    @cqp_bin = @cqp_path + CQP_CMD
    @cwb_lexdecode_bin = @cqp_path + CWB_LEXDECODE_CMD
    
    @context = query_context

    # if this is a "search query" and we are not passed an id
    # we run the query and dump the results for future use
    if @context.id.nil? and @context.query_spec
      @context.id = run_query
    end
  end
  
  # Run the query and set up a CQP dump file as cache.
  # Normally run as a part of instance initialization.
  #
  # Returns an id string identifying the dump file.
  #
  # NOTE: Temporary files made by this method are not deleted
  # and must be cleaned up manually.
  def run_query
    # Use the same id for all temporary files
    id = SimpleCQP.make_id

    # create files, query and execute the query
    run_file = SimpleCQP.make_temp_file "run", id
    out_file = SimpleCQP.make_temp_file "result", id
    error_file = SimpleCQP.make_temp_file "error", id
    dump_file = SimpleCQP.make_temp_file "dump", id

    subcorpus = "simple.#{id}"
    # build query from spec
    query_string = build_cqp_query @context.query_spec

    query_op = StringIO.new
 
    query_op << "set DataDirectory \"#{TEMP_DIR}\";\n"
    query_op << "#{@context.corpus};\n"
    query_op << "#{subcorpus} = #{query_string};\n"
    query_op << "dump #{subcorpus} > \"#{dump_file}\";\n"
    
    execute_query query_op.string
    
    # rewrite the dump file into a format that can be read back in
    SimpleCQP.fix_dump_file(dump_file)
    
    return id
  end
  
  # Extract results from the query run by this instance.
  #
  # Recreates the query from the dump file and extracts
  # the requested results.
  #
  # from - index of the first result returned as an integer.
  # to   - index of the last result returned as an integer.
  #
  # Returns the results produced by CQP as an array of strings.
  # NOTE: the index parameters are passed directly to the
  # CQP CAT command.
  def result(from = nil, to = nil)
    subcorpus = "simple.#{@context.id}"
    # Dump file is identified by the contexts id
    dump_file = SimpleCQP.make_temp_file "dump", @context.id
    
    # set up the query
    full_query_op = StringIO.new
    full_query_op << "#{@context.corpus};\n"
    @context.alignment.each { |a| full_query_op << "show +#{a};\n" }
    full_query_op << "set LeftContext #{@context.left_context} #{@context.context_type};\n"
    full_query_op << "set RightContext #{@context.right_context} #{@context.context_type};\n"
    full_query_op << %Q(set LD '<span class="search-result">';\n)
    full_query_op << %Q(set RD '</span>';\n)
    full_query_op << "undump #{subcorpus} < \"#{dump_file}\";\n"
    if from && to
      full_query_op << "cat #{subcorpus} #{from} #{to};\n"
    else
      full_query_op << "cat #{subcorpus};\n"
    end

    result = execute_query(full_query_op.string)

    return SimpleCQP.group_result_by_alignment result, @context.alignment
  end

  # Groups the result into arrays of lines corresponding to the
  # alignments of the query.
  # result    - the result from a query, an array of strings.
  # alignment - the alignments used by the query, an array of strings
  #   specifying CWB corpora.
  # Returns the grouped result, an array of arrays containing the strings
  # of results from each corpora ordered as they are returned from CQP
  # (this should be main corpora followed by aligned corpora in the same
  # order as in @context.alignment).
  def self.group_result_by_alignment(result, alignment)
    group_size = alignment.length + 1
    
    # sanity checking of the passed results
    raise RuntimeError if (result.length % group_size) != 0
    
    i = 0
    groups = []

    while i < result.length
      group = result[i...(group_size + i)]
      groups << group
      i += group_size
    end

    return groups
  end

  # Gives the number of results in the query run by this instance
  #
  # Returns the number of results as an integer
  def query_size
    # no query has been run if there is no id
    raise RuntimeError if @context.id.nil?
    
    subcorpus = "simple.#{@context.id}"
    # the dump file is identified by the id in the context
    dump_file = SimpleCQP.make_temp_file "dump", @context.id
 
    full_query_op = StringIO.new
    full_query_op << "#{@context.corpus};\n"
    full_query_op << "undump #{subcorpus} < \"#{dump_file}\";\n"
    full_query_op << "size #{subcorpus};\n"
    
    result = execute_query(full_query_op.string)

    # we should get one result line containing the size number
    raise RuntimeError if result.count != 1
    
    return result[0].to_i
  end
  
  # List available corpora given the registry in the context of this instance.
  #
  # Returns an array of strings with the corpora names as given by CWB.
  def list_corpora
    # Build and execute query
    full_query = "show corpora;\n"

    result_lines = execute_query(full_query)
    
    # Check that the result includes the "System corpora:" line
    raise RuntimeError if result_lines.count < 1 or not result_lines[0].include?("System corpora:")
    
    # Remove the "System corpora:" line
    result_lines.delete_at 0
    
    # Collect corpus names by taking each output line, splitting it, removing the initial header
    # and add the remaining strings
    result = []
    
    result_lines.each do |line|
      line.split[1..-1].each { |c| result << c }
    end

    return result
  end

  # Gives the corpus info as provided by CWB
  #
  # corpus - A string describing the corpus as required by CWB
  #
  # Returns a Hash containing the following keys:
  # :size    - The corpus size as an integer.
  # :charset - A description of the corpus charset as a string.
  def corpus_info(corpus)
    full_query = "info #{corpus};\n"
    
    result = execute_query(full_query, :ignore_warnings => true)

    return {
      :size => result[0].split.last.to_i,
      :charset => result[1].split.last
    }
  end
  
  # Finds all values used for a given attribute in the corpus set in the context.
  #
  # attribute - A string specifying an attribute encoded in the corpus.
  #
  # Returns an array of attribute values as strings.
  def attribute_lexicon(attribute)
    pipe = IO.popen "#{@cwb_lexdecode_bin} -r #{@context.registry} -P #{attribute} #{@context.corpus}"
    
    # TODO: handle errors
    result = pipe.readlines.each { |line| line.strip! }
    pipe.close

    return result
  end
  
  # Executes a CQP query
  #
  # full_query_string - The full set of query commands as a string,
  #   each CQP command terminated by a semicolon and a newline.
  #
  # Options:
  # :ignore_warnings - Ignore CQP errors marked as warning in the CQP
  #   error output.
  #
  # Returns an array containing the lines of the query result.
  def execute_query(full_query_string, opts={})
    # Set options
    ignore_warnings = opts[:ignore_warnings] || false
    
    # Generate temporary file names for the query and results
    query_file = SimpleCQP.make_temp_file "query"
    error_file = SimpleCQP.make_temp_file "error"
    result_file = SimpleCQP.make_temp_file "result"
    
    # Write the query to a temporary file
    File.open(query_file, 'w') do |f|
      f.puts full_query_string
    end
    
    # Execute the query, all input/output from/to temporary files
    pipe = IO.popen("#{@cqp_bin} -c -r #{@context.registry} < #{query_file} 1> #{result_file} 2> #{error_file}")
    pipe.close
    
    # Check the error file and potentially raise an error
    if File.size(error_file) != 0
      # Collect error records
      errors = SimpleCQP.parse_errors(error_file)
      
      # Collect error type symbols
      types = errors.collect { |err| err.first }

      # Ignore warnings of all errors are warnings and the option is set
      if not (ignore_warnings and types.all? { |t| t == :warning })
         raise RuntimeError
      end
    end

    # Read the query result from the temporary result file
    result_strings = nil
    
    File.open(result_file) do |f|
      result_strings = f.readlines
    end
    
    # Strip off the CQP version info always included in the result
    SimpleCQP.remove_version result_strings
    
    # Remove temporary files and return the result strings
    File.delete(query_file)
    File.delete(error_file)
    File.delete(result_file)
    
    return result_strings.each { |str| str.strip! }
  end

  # Convert the dump file specified by the filename
  # to a file in an undumpable format.
  #
  # filename - A string containing the name of a file produced
  #   by the CQP dump command.
  #
  # Returns nil.
  def self.fix_dump_file(filename)
    lines = []
    
    File.open(filename) do |f|
      f.each_line do |line|
        lines << line.split
      end
    end

    File.open(filename, 'w') do |f|
      f.puts lines.count

      lines.each do |line|
        f.puts "#{line[0]}\t#{line[1]}"
      end
    end

    nil
  end
  
  # Create a temporary filename, distinguished by a time
  # based id.
  #
  # name - The descriptive part of the generated file name
  #        as a string.
  # id   - An id as a string, if passed nil a time based id
  #        will be generated.
  #
  # Returns the temporary filename as a string.
  def self.make_temp_file(name, id = nil)
    id = make_id if id.nil?

    return "#{TEMP_DIR}#{name}-#{id}"
  end
  
  # Creates an id string based on the current time with
  # millisecond accuracy.
  #
  # Returns an id string.
  def self.make_id
    Time.now.to_f.to_s
  end

  def self.remove_version(result)
    # check that the version header is included in the result
    raise RuntimeError if result[0].index("CQP version") != 0

    result.delete_at 0

    return result
  end
  
  # Parse an error file written by CQP, categorizing
  # each error and collecting the error info.
  #
  # error_file - A string with the filename of the error file.
  #
  # Returns an array of error records consisting of an array headed
  # by a symbol denoting the error type, followed on or more strings
  # describing the error.
  def self.parse_errors(error_file)
    errors = []
    last = nil
    
    File.open(error_file) do |f|
      # Check each line, if it's an error header, store existing
      # error in result, otherwise add the content in the line to
      # the error record.
      f.each_line do |line|
        type = error_header_line? line

        if type
          errors << last if last
          last = [type]
        elsif error_content_line? line
          last << line
        else
          raise RuntimeError
        end
      end
    end
    
    # Remember to add the last error processed
    errors << last if last

    return errors
  end

  # Identifies lines "heading" error information in the
  # error output.
  #
  # line - a line from the error output as a string.
  #
  # Returns the error type indicated by the heading, or
  # nil if the line is not a header.
  def self.error_header_line?(line)
    if line.strip == "Warning:"
      return :warning
    elsif line.strip == "CQP Error:"
      return :cqp_error
    else
      return nil
    end
  end
  
  # Check if a line from the error output contains error
  # message content.
  #
  # Returns true if the line contains error content.
  def self.error_content_line?(line)
    line.match("^\t")
  end
  
  # Generates a CQP query from a query spec - see comments
  # in cqp_query_context.rb.
  #
  # query_spec - An array with corpus names and valid
  #   corpora specific query sub specs.
  #
  # Returns the corresponding CQP query as a string.
  def build_cqp_query(query_spec)
    other_clauses = query_spec.select { |query| query[:corpus].to_s.upcase != @context.corpus }

    main_spec = query_spec.find { |query| query[:corpus].to_s.upcase == @context.corpus }

    full_clause = StringIO.new
    full_clause << build_cqp_corpus_query(main_spec)

    other_clauses.each do |clause|
      full_clause << " :#{clause[0].to_s.upcase} #{build_cqp_corpus_query clause[1]}"
    end

    return full_clause.string
  end
  
  # Generates a CQP corpus sub query from a sub spec - see
  # comments in cqp_query_context.rb.
  #
  # query_spec - An array of hashes that is a valid query sub
  #   sub spec for a corpus specific part of a query.
  #
  # Returns the corresponding CQP query as a string.
  def build_cqp_corpus_query(query_spec)
    # generate clause strings for each sub-specification
    clauses = []
    query_spec[:terms].collect do |spec|
      clauses << build_cqp_interval_query(spec)
      clauses << build_cqp_word_query(spec)
    end

    return clauses.join(' ')
  end
  
  # Builds an interval clause from an interval sub-specification.
  # Used by the build_cqp_query method.
  #
  # interval_spec - A hash that is a valid interval spec.
  #
  # Returns the corresponding clause as a string.

  # TODO support ?, *, within s
  
  def build_cqp_interval_query(query_term)
    min = query_term['min']
    max = query_term['max']
    return '' unless min || max

    min = '0' if min.nil?
    max = '' if max.nil?
    "[]{#{min}, #{max}}"
  end
  
  # Builds a word clause from a word sub-specification.
  # Used by the build_cqp_query method.
  #
  # word_spec - A hash that is a valid word spec.
  #
  # Returns the corresponding clause as a string.
  def build_cqp_word_query(query_term)
    # start with the word subclause
    clauses = ["(word='#{query_term['string']}'#{'%c' if @context.case_insensitive})"]

    # add attribute subclauses if we have any
    if query_term['attributes']
      query_term['attributes'].each_pair do |attr, val|
        clauses << "(#{attr}='#{val}')"
      end
    end

    # add surrounding brackets and conjunction operators
    return "[" + clauses.join(" & ") + "]"
  end
end
