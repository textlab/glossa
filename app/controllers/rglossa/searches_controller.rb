class Rglossa::SearchesController < ApplicationController
  respond_to :json, :xml

  def index
    @searches = current_user.searches
    respond_with(@searches)
  end

  def create
    @search = model_class.create(params[model_param])

    respond_to do |format|
      format.any(:json, :xml) do
        render request.format.to_sym =>
          @search.to_json(methods: :first_result_page)
      end
    end
  end

  def page
    search = current_user.searches.find(model_param_id)
    @results = search ? search.get_result_page(page) : nil
    respond_with(@results)
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

  ########
  private
  ########

  # The name of the search model as it occurs in query parameters, e.g.
  # "cwb_search"
  def model_param
    # model_class is defined by derived controllers for the individual search
    # types we support
    model_class.to_s.demodulize.underscore
  end

  def model_param_id
    "#{model_param}_id"
  end

  def page_size
    20
  end
end