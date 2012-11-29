class Rglossa::MetadataValue < ActiveRecord::Base
  belongs_to :metadata_category
  validates_presence_of :metadata_category_id

  class << self

    # Fetches the ids of all metadata values belonging to the given category
    # that are associated with the same corpus texts as a particular other
    # metadata value (belonging to another category).
    #
    # This is used for creating filtered lists. For instance, it might return
    # a list of all book titles written by a particular author by finding all
    # titles that are associated with the same corpus texts as the author.
    #
    # We achieve this by doing a self join on the corpus_texts_metadata_values
    # table constrained on the corpus_text id and constraining one of the
    # joined tables to the given category and the other to the given value.
    def ids_filtered_by_other_category(this_category_id, other_category_value_id)
      MetadataValue.find_by_sql([
        'SELECT DISTINCT vals.id from metadata_values vals ' +

        'INNER JOIN corpus_texts_metadata_values j1 ' +
        'ON j1.metadata_value_id = vals.id ' +

        'INNER JOIN corpus_texts_metadata_values j2 ' +
        'ON j2.corpus_text_id = j1.corpus_text_id ' +

        'WHERE vals.metadata_category_id = ? AND j2.metadata_value_id = ?',

        this_category_id, other_category_value_id
      ])
    end
  end
end
