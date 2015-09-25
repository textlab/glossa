require 'ostruct'

class Corpus < OpenStruct

  def multilingual?
    languages.class == Array && languages.size > 1
  end

  def speech_corpus?
    has_sound || has_video
  end

  def metadata_category_ids
    metadata_categories.pluck(:id)
  end

  def langs
    if languages
      languages.map do |l|
        res = {lang: l[:lang]}
        tagger_config = Rglossa.taggers[l[:tagger].to_s]

        if tagger_config
          res.merge!({
            displayAttrs: tagger_config['displayAttrs'],
            tags: tagger_config['tags']
          })
        end
        res
      end
    else
      []
    end
  end
end
