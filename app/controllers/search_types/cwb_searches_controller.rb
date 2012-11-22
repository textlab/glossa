class SearchTypes::CwbSearchesController < SearchesController
  respond_to :json, :xml

  def create
    @search = SearchTypes::CwbSearch.create(params[:cwb_search])
    super
  end

end
