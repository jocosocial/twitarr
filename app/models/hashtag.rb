# frozen_string_literal: true

# == Schema Information
#
# Table name: hashtags
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hashtags_on_name  (name) UNIQUE
#

class Hashtag < ApplicationRecord
  MIN_AUTO_COMPLETE_LEN = 3
  AUTO_COMPLETE_LIMIT = 10
  MAX_LENGTH = 100

  validates :name, length: { maximum: MAX_LENGTH }

  def self.add_tag(hashtag)
    hashtag = hashtag[1..] if hashtag[0] == '#'
    begin
      doc = Hashtag.find_or_create_by(name: hashtag.downcase.strip)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    doc
  rescue StandardError => e
    logger.error e
  end

  def self.auto_complete(prefix)
    prefix = prefix.downcase.strip
    Hashtag.where('name like ?', "#{prefix}%").order(name: :asc).limit(AUTO_COMPLETE_LIMIT)
  end

  # this is probably not going to be a fast operation
  def self.repopulate_hashtags
    StreamPost.all.pluck(:hash_tags).flatten.uniq.each do |ht|
      Hashtag.add_tag ht
    end
    ForumPost.all.pluck(:hash_tags).flatten.uniq.each do |ht|
      Hashtag.add_tag ht
    end
  end
end
