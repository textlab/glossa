module Rglossa
  class CorpusSerializer < ActiveModel::Serializer
    embed :ids, include: true

    attributes :id, :name, :short_name

    has_many :metadata_categories
  end
end