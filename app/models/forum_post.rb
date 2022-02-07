# frozen_string_literal: true

# == Schema Information
#
# Table name: forum_posts
#
#  id              :bigint           not null, primary key
#  author          :bigint           not null
#  hash_tags       :string           default([]), not null, is an Array
#  mentions        :string           default([]), not null, is an Array
#  original_author :bigint           not null
#  text            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  forum_id        :bigint           not null
#
# Indexes
#
#  index_forum_posts_on_author                   (author)
#  index_forum_posts_on_forum_id_and_created_at  (forum_id,created_at)
#  index_forum_posts_on_hash_tags                (hash_tags) USING gin
#  index_forum_posts_on_mentions                 (mentions) USING gin
#  index_forum_posts_text                        (to_tsvector('english'::regconfig, (text)::text)) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (author => users.id)
#  fk_rails_...  (forum_id => forums.id) ON DELETE => cascade
#  fk_rails_...  (original_author => users.id)
#

class ForumPost < ApplicationRecord
  include Searchable
  include Postable

  has_many :post_reactions, dependent: :destroy
  has_many :reactions, through: :post_reactions
  belongs_to :forum, inverse_of: :posts, counter_cache: true
  belongs_to :user, class_name: 'User', foreign_key: :author, inverse_of: :forum_posts

  has_many :post_photos, dependent: :destroy
  has_many :photo_metadata, class_name: 'PhotoMetadata', through: :post_photos

  validates :author, :original_author, presence: true
  validates :text, presence: true, length: { maximum: 10000 }

  before_validation :parse_hash_tags
  before_save :post_create_operations

  after_commit :update_cache
  delegate :update_cache, to: :forum

  def self.new_post(forum_id, author, text, photos, original_author)
    post = ForumPost.new(forum_id:, author:, text:, original_author:)
    photos&.each do |photo|
      post.post_photos << PostPhoto.new(photo_metadata_id: photo)
    end
    post
  end
end
