class MetadataValueSerializer < ActiveModel::Serializer
  embed :ids

  attributes :id, :metadata_category_id, :text
end
