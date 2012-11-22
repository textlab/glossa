class SearchTypes::CwbSearchesController < SearchesController

  # Used by the base controller to find the right kind of model to manipulate
  def model
    SearchTypes::CwbSearch
  end

end
