module Rglossa
  class SearchEngines::CwbSearchesController < SearchesController

    # Used by the base controller to find the right kind of model to work with
    def model_class
      SearchEngines::CwbSearch
    end

  end
end