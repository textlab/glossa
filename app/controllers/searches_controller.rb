class SearchesController < ApplicationController
  def create
    unless params.has_key?(:data)
      render :json => {:success => false, :message => 'Data parameter is missing'}, :status => :bad_request
      return
    end

    unless params[:data].is_a?(Hash) && params[:data].has_key?(:queries)
      render :json => {:success => false, :message => 'Queries parameter is missing'}, :status => :bad_request
      return
    end

#    unless params[:data].has_ke
#    current_user.searches.create!(params[:data]) if current_user
  end
  
  # Non restful endpoint for CQP/CWB queries
  def query
    queries = params[:queries]
    corpus = params[:queries].first[:corpus].upcase
    query_id = params[:queryId]
    case_insensitive = params[:caseInsensitive]
    start = params[:start]  # may be undefined if paging is not used
    limit = params[:limit]  # may be undefined if paging is not used

    cwb_settings = read_cwb_settings

    query_id = query_id.to_f

    # a 0 id sent by the app means no id is given
    if query_id == 0
      query_id = nil
    end

    context = CQPQueryContext.new(:registry => cwb_settings['registry'],
                                  :query_spec => queries,
                                  :id => query_id,
                                  :corpus => corpus,
                                  :case_insensitive => (case_insensitive == "true"))
    
    cqp = SimpleCQP.new(context, :cqp_path => cwb_settings['cwb_bin_path'])
    @result = cqp.result(start.to_i, start.to_i + limit.to_i - 1)

    render :json => {
      :queryId => context.id,
      :data => lines_to_json(@result),
      :querySize => cqp.query_size,
      :success => true
    }
  end
  
  # non restful endpoint for CQP/CWB corpora list requests
  def corpora_list
    id = params[:id]
    
    cwb_settings = read_cwb_settings
    
    context = CQPQueryContext.new(:registry => cwb_settings['registry'])
    cqp = SimpleCQP.new context, :cqp_path => cwb_settings['cwb_bin_path']
    corpora = cqp.list_corpora

    render :json => {
      :data => corpora.collect { |c| { :corpus => c } },
      :success => true
    }
  end
  
  # non restful endpoint for CQP/CWB corpus info requests
  def corpus_info
    corpus = params[:corpus]

    cwb_settings = read_cwb_settings
    
    context = CQPQueryContext.new(:registry => cwb_settings['registry'])
    cqp = SimpleCQP.new context, :cqp_path => cwb_settings['cwb_bin_path']
    
    corpus_info = cqp.corpus_info corpus

    render :json => corpus_info
  end

  def destroy
  end
  
  # helper that  reads CWB/CQP settings from a config file
  def read_cwb_settings
    return YAML.load_file("#{Rails.root}/config/cwb.yml")[Rails.env]
  end

  # helper that format CQP result lines to JSON
  def lines_to_json(result)
    result.collect do |line|
      { :guid => line.first.match(/^\d+/)[0], :line => line }
    end
  end
end
