require 'yaml'

require 'simple_cqp'
require 'cqp_query_context'

$cwb_settings = YAML.load_file("config/cwb.yml")["test"]

describe SimpleCQP do 
  it "should return all corpora in the registry" do
    ctx = CQPQueryContext.new :registry => $cwb_settings['registry']
    cqp = SimpleCQP.new ctx, :cqp_path => $cwb_settings['cwb_bin_path']

    corpora = cqp.list_corpora

    corpora.count.should == 3
    corpora.should include "ARABIC_U"
    corpora.should include "ARABIC_V"
    corpora.should include "ENGLISH"
  end

  it "should provide size and charset for a given corpora" do
    ctx = CQPQueryContext.new :registry => $cwb_settings['registry']
    cqp = SimpleCQP.new ctx, :cqp_path => $cwb_settings['cwb_bin_path']
    
    info = cqp.corpus_info "ENGLISH"
    info[:size].should == 14092
    info[:charset].should == "ascii"
  end

  it "should execute queries without raising errors" do
    ctx = CQPQueryContext.new :registry => $cwb_settings['registry'], :corpus => "ENGLISH"
    cqp = SimpleCQP.new ctx, :cqp_path => $cwb_settings['cwb_bin_path']

    result = cqp.execute_query ".EOL.;\n"
    result.should == ["-::-EOL-::-"]
  end

  it "should return the correct corpora lines for a simple query" do
    ctx = CQPQueryContext.new(:registry => $cwb_settings['registry'],
                              :corpus => "ENGLISH",
                              :query_spec => { :english => [{ 'type' => 'word', 'string' => 'beneficent' }]},
                              :case_insensitive => true)
    cqp = SimpleCQP.new ctx, :cqp_path => $cwb_settings['cwb_bin_path']

    cqp.query_size.should == 4
    
    result = cqp.result(0, 4)
    line_nums = result.collect { |line| line.match("^\\s*(\\d+):")[1].to_i }

    line_nums.should == [7, 23, 6698, 8371]
  end

  it "should return the correct lexicon for an attribute in a given corpus" do
    ctx = CQPQueryContext.new(:registry => $cwb_settings['registry'],
                              :corpus => "ENGLISH")
    cqp = SimpleCQP.new ctx, :cqp_path => $cwb_settings['cwb_bin_path']

    result = cqp.attribute_lexicon "pos"

    result.count.should == 39

    result.should include "IN"
    result.should include "DT"
    result.should include "NN"
    result.should include "NNP"
    result.should include ","
    result.should include "."
    result.should include "VB"
    result.should include "TO"
    result.should include "NNPS"
    result.should include "("
    result.should include "RB"
    result.should include ")"
    result.should include "PRP"
    result.should include ":"
    result.should include "VBP"
    result.should include "JJ"
    result.should include "WP"
    result.should include "VBD"
    result.should include "CC"
    result.should include "VBZ"
    result.should include "EX"
    result.should include "VBN"
    result.should include "WDT"
    result.should include "PRP$"
    result.should include "NNS"
    result.should include "MD"
    result.should include "WRB"
    result.should include "VBG"
    result.should include "CD"
    result.should include "RP"
    result.should include "FW"
    result.should include "JJR"
    result.should include "WP$"
    result.should include "PDT"
    result.should include "POS"
    result.should include "JJS"
    result.should include "RBS"
    result.should include "UH"
    result.should include "RBR"
  end

  it "should generate correct CQP queries given a more complex query spec" do
    spec = { :english => [{'type' => 'word', 'string' => "lord", 'attributes' => { :pos => "NNP" }},
                          {'type' => 'interval', 'min' =>0, 'max'=>3},
                          {'type' => 'word', 'string' => "worlds"}]}
    
    ctx = CQPQueryContext.new(:registry => $cwb_settings['registry'],
                              :corpus => "ENGLISH",
                              :query_spec => spec,
                              :case_insensitive => true)
    cqp = SimpleCQP.new ctx, :cqp_path => $cwb_settings['cwb_bin_path']
    
    cqp.query_size.should == 2
    result = cqp.result 0, 2
    line_nums = result.collect { |line| line.match("^\\s*(\\d+):")[1].to_i }
    line_nums.should == [17, 5339]
  end

  it "should return the correct clause for a query word sub spec" do
    spec = { 'type' => 'word', 'string' => 'the', 'attributes' => { :pos => 'DT' } }
    ctx = CQPQueryContext.new
    cqp = SimpleCQP.new ctx
    clause = cqp.build_cqp_word_query spec
    clause.should == "[(word='the') & (pos='DT')]"

    spec = { 'type' => 'word', 'string' => 'the' }
    ctx = CQPQueryContext.new :case_insensitive => true
    cqp = SimpleCQP.new ctx
    clause = cqp.build_cqp_word_query spec
    clause.should == "[(word='the'%c)]"
  end

  it "should return the correct clause for an interval sub spec" do
    ctx = CQPQueryContext.new
    cqp = SimpleCQP.new ctx
    
    spec = { 'type' => 'interval', 'min' => 1, 'max' => 3 }
    clause = cqp.build_cqp_interval_query spec
    clause.should == "[]{1, 3}"

    spec = { 'type' => 'interval', 'min' => 0, 'max' => 0 }
    clause = cqp.build_cqp_interval_query spec
    clause.should == "[]{0, 0}"

    spec = { 'type' => 'interval', 'min' => 1, 'max' => 1 }
    clause = cqp.build_cqp_interval_query spec
    clause.should == "[]{1, 1}"
  end

  it "should return a correct clause for a corpus specific sub spec" do
    ctx = CQPQueryContext.new
    cqp = SimpleCQP.new ctx
    spec = [{ 'type' => 'word', 'string' => 'the'},
            { 'type' => 'interval', 'min' => 0, 'max' => 0},
            { 'type' => 'word', 'string' => 'lord'},
            { 'type' => 'interval', 'min' => 1, 'max' => 3},
            { 'type' => 'word', 'string' => 'worlds'}]
    clause = cqp.build_cqp_corpus_query spec
    clause.should == "[(word='the')] []{0, 0} [(word='lord')] []{1, 3} [(word='worlds')]"
  end

  it "should return the correct clause for a query spec" do
    ctx = CQPQueryContext.new :corpus => "ENGLISH"
    cqp = SimpleCQP.new ctx

    spec = { :english => [{ 'type' => 'word', 'string' => 'the' }]}
    clause = cqp.build_cqp_query spec
    clause.should == "[(word='the')]"

    spec = {
      :english => [{ 'type' => 'word', 'string' => 'the' }],
      :arabic_u => [{ 'type' => 'word', 'string' => 'fy' }]}
    
    clause = cqp.build_cqp_query spec
    clause.should == "[(word='the')] :ARABIC_U [(word='fy')]"

    spec = {
      :english => [{ 'type' => 'word', 'string' => 'the' }],
      :arabic_u => [{ 'type' => 'word', 'string' => 'fy' }],
      :arabic_v => [{ 'type' => 'word', 'string' => 'fiy' }]}

    clause = cqp.build_cqp_query spec
    # sequence of aligned corpora doesn't matter
    ["[(word='the')] :ARABIC_U [(word='fy')] :ARABIC_V [(word='fiy')]",
     "[(word='the')] :ARABIC_V [(word='fiy')] :ARABIC_U [(word='fy')]"].should include clause
  end
end
