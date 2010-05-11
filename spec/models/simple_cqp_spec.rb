require 'simple_cqp'
require 'cqp_query_context'

$test_registry = "test/cwb_test_data/reg"

describe SimpleCQP do 
  it "should return all corpora in the registry" do
    ctx = CQPQueryContext.new :registry => $test_registry
    cqp = SimpleCQP.new ctx

    corpora = cqp.list_corpora

    corpora.count.should == 3
    corpora.should include "ARABIC_U"
    corpora.should include "ARABIC_V"
    corpora.should include "ENGLISH"
  end

  it "should provide size and charset for a given corpora" do
    ctx = CQPQueryContext.new :registry => $test_registry
    cqp = SimpleCQP.new ctx
    
    info = cqp.corpus_info "ENGLISH"
    info[:size].should == 14092
    info[:charset].should == "ascii"
  end

  it "should execute queries without raising errors" do
    ctx = CQPQueryContext.new :registry => $test_registry, :corpus => "ENGLISH"
    cqp = SimpleCQP.new ctx

    result = cqp.execute_query ".EOL.;\n"
    result.should == ["-::-EOL-::-"]
  end

  it "should return the correct corpora lines for a simple query" do
    ctx = CQPQueryContext.new(:registry => $test_registry,
                              :corpus => "ENGLISH",
                              :query_string => 'beneficent',
                              :case_insensitive => true)
    cqp = SimpleCQP.new ctx

    cqp.query_size.should == 4
    
    result = cqp.result(0, 4)
    line_nums = result.collect { |line| line.match("^\\s*(\\d+):")[1].to_i }

    line_nums.should == [7, 23, 6698, 8371]
  end

  it "should return the correct lexicon for an attribute in a given corpus" do
    ctx = CQPQueryContext.new(:registry => $test_registry,
                              :corpus => "ENGLISH")
    cqp = SimpleCQP.new ctx

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
end
