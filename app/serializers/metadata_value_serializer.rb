class MetadataValueSerializer < ActiveModel::Serializer
  attributes :id, :metadata_category_id, :text
end
