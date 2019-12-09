class Hashtag
  include Mongoid::Document

  MIN_AUTO_COMPLETE_LEN = 3
  AUTO_COMPLETE_LIMIT = 10

  field :_id, type: String, as: :name

  def self.add_tag(hashtag)

    hashtag = hashtag[1..-1] if hashtag[0] == '#'
    hashtag = hashtag.downcase
    hashtag.strip!
    doc = Hashtag.new(name: hashtag)
    doc.upsert
    doc
  rescue StandardError => e
    logger.error e

  end

  def self.auto_complete(prefix)
    prefix = prefix.downcase
    Hashtag.where(name: /^#{prefix}/).asc(:name).limit(AUTO_COMPLETE_LIMIT)
  end

  # this is probably not going to be a fast operation
  def self.repopulate_hashtags
    StreamPost.distinct(:hash_tags).each do |ht|
      Hashtag.add_tag ht
    end
    ForumPost.distinct(:hash_tags).each do |ht|
      Hashtag.add_tag ht
    end
  end
end
