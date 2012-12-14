module Rglossa
  class SearchTypes::CwbSearchSerializer < ActiveModel::Serializer
    attributes :id, :num_hits
  end
end