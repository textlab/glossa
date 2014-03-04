module Rglossa
  module Speech
    module SearchEngines
      class CwbSearchesController < Rglossa::SearchEngines::CwbSearchesController

        # Used by the base controller to find the right kind of model to work with
        def model_class
          SpeechCwbSearch
        end

      end
    end
  end
end