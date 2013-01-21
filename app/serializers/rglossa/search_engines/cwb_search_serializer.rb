module Rglossa
  class SearchEngines::CwbSearchSerializer < ActiveModel::Serializer
    attributes :id, :num_hits
  end
end