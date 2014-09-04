module Rglossa
  module Speech
    module SearchEngines
      class SpeechCwbSearch < ::Rglossa::SearchEngines::CwbSearch

        def default_context_size
          7
        end

      end
    end
  end
end
