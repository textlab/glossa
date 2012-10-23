class MetadataCategorySerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :corpus_id, :name

  has_many :metadata_values
end
