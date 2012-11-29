class MetadataCategorySerializer < ActiveModel::Serializer
  embed :ids, include: true

  attributes :id, :corpus_id, :name

  has_many :metadata_values
end
