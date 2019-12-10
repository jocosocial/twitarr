# == Schema Information
#
# Table name: forum_posts
#
#  id              :bigint           not null, primary key
#  author          :bigint           not null
#  original_author :bigint           not null
#  text            :string           not null
#  mentions        :string           default([]), not null, is an Array
#  hash_tags       :string           default([]), not null, is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  forum_id        :bigint           not null
#
# Indexes
#
#  index_forum_posts_on_author      (author)
#  index_forum_posts_on_created_at  (created_at)
#  index_forum_posts_on_hash_tags   (hash_tags) USING gin
#  index_forum_posts_on_mentions    (mentions) USING gin
#  index_forum_posts_text           (to_tsvector('english'::regconfig, (text)::text)) USING gin
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

  # field :ph, as: :photos, type: Array

  has_many :post_reactions, dependent: :destroy
  belongs_to :forum, inverse_of: :posts
  belongs_to :user, class_name: 'User', foreign_key: :author, inverse_of: :forum_posts

  validates :author, :original_author, presence: true
  validates :text, presence: true, length: { maximum: 10000 }

  before_validation :parse_hash_tags
  before_save :post_create_operations

  after_save :update_cache
  after_destroy :update_cache
  delegate :update_cache, to: :forum

  has_many :post_photos, dependent: :destroy
  has_many :photo_metadatas, class_name: 'PhotoMetadata', through: :post_photos
end
