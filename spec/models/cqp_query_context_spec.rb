require 'cqp_query_context'

describe CQPQueryContext do
  it "should return correct aligned corpora based on the query" do
    spec = {
      'english' => [{ 'type' => 'word', 'string' => 'the' }],
      'arabic_u' => [{ 'type' => 'word', 'string' => 'fy' }],
      'arabic_v' => [{ 'type' => 'word', 'string' => 'fiy' }]}

    ctx = CQPQueryContext.new :corpus => "ENGLISH", :query_spec => spec

    alignments = ctx.alignment_from_query

    alignments.length.should == 2
    alignments.should include "arabic_u"
    alignments.should include "arabic_v"
  end
end
