module Rglossa
  module Speech
    module SearchEngines
      class SpeechCwbSearchesController < Rglossa::SearchEngines::CwbSearchesController

        # Used by the base controller to find the right kind of model to work with
        def model_class
          SpeechCwbSearch
        end

        def geo_distr
          search = model_class.find(params[:id])
          distribution = search.geo_distr
          render json: distribution
        end
      end
    end
  end
end
