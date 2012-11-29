class CorpusSerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :name

  has_many :metadata_categories
end
