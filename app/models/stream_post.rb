# == Schema Information
#
# Table name: stream_posts
#
#  id              :bigint           not null, primary key
#  author          :bigint           not null
#  original_author :bigint           not null
#  text            :string           not null
#  location_id     :bigint
#  locked          :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_chain    :bigint           default([]), is an Array
#  mentions        :string           default([]), not null, is an Array
#  hash_tags       :string           default([]), not null, is an Array
#
# Indexes
#
#  index_stream_posts_on_author        (author)
#  index_stream_posts_on_hash_tags     (hash_tags) USING gin
#  index_stream_posts_on_location_id   (location_id)
#  index_stream_posts_on_mentions      (mentions) USING gin
#  index_stream_posts_on_parent_chain  (parent_chain) USING gin
#  index_stream_posts_text             (to_tsvector('english'::regconfig, (text)::text)) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (author => users.id)
#  fk_rails_...  (location_id => locations.id) ON DELETE => nullify
#  fk_rails_...  (original_author => users.id)
#

# noinspection RubyStringKeysInHashInspection
class StreamPost < ApplicationRecord
  include Postable
  include Searchable

  belongs_to :user, class_name: 'User', foreign_key: :author, inverse_of: :stream_posts

  has_many :post_reactions, dependent: :destroy
  has_many :reactions, class_name: 'Reaction', through: :post_reactions

  has_one :post_photo, dependent: :destroy
  has_one :photo_metadata, class_name: 'PhotoMetadata', through: :post_photo

  validates :author, :original_author, presence: true
  validates :text, presence: true, length: { maximum: 2000 }
  # validate :validate_location

  after_destroy :reparent_children

  before_validation :parse_hash_tags
  before_save :post_create_operations

  pg_search_scope :pg_search,
                  against: :text,
                  associated_against: { user: [:username, :display_name] },
                  using: {
                      trigram: { word_similarity: true },
                      tsearch: { any_word: true, prefix: true }
                  }

  def self.at_or_before(ms_since_epoch, options = {})
    query = where('stream_posts.created_at <= ?', Time.at(ms_since_epoch.to_i / 1000.0))
    query = query.where('stream_posts.author IN (?)', options[:filter_authors]) if options.key?(:filter_authors) && !options[:filter_authors].nil?
    query = query.joins(:user).where(users: { username: options[:filter_author] }) if options.key?(:filter_author) && !options[:filter_author].nil?
    # query = query.where(:'rn.un' => options[:filter_reactions]) if options.has_key? :filter_reactions and !options[:filter_reactions].nil?
    # query = query.where(hash_tags: options[:filter_hashtag]) if options.has_key? :filter_hashtag and !options[:filter_hashtag].nil?
    if options.key?(:filter_mentions) && !options[:filter_mentions].nil?
      query = if options[:mentions_only]
                query.where('mentions @> ?', "{#{options[:filter_mentions]}}")
              else
                query.where('mentions @> ?', "{#{options[:filter_mentions]}}").or(query.where(author: options[:filter_mentions]))
              end
    end
    query
  end

  def self.at_or_after(ms_since_epoch, options = {})
    query = where('stream_posts.created_at >= ?', Time.at(ms_since_epoch.to_i / 1000.0))
    query = query.where(:author.in => options[:filter_authors]) if options.key?(:filter_authors) && !options[:filter_authors].nil?
    query = query.joins(:user).where(users: { username: options[:filter_author] }) if options.key?(:filter_author) && !options[:filter_author].nil?
    # query = query.where(:'rn.un' => options[:filter_reactions]) if options.has_key? :filter_reactions and !options[:filter_reactions].nil?
    # query = query.where(hash_tags: options[:filter_hashtag]) if options.has_key? :filter_hashtag and !options[:filter_hashtag].nil?
    if options.key?(:filter_mentions) && !options[:filter_mentions].nil?
      query = if options[:mentions_only]
                query.where('mentions @> ?', "{#{options[:filter_mentions]}}")
              else
                query.where('mentions @> ?', "{#{options[:filter_mentions]}}").or(query.where(author: options[:filter_mentions]))
              end
    end
    query
  end

  def self.thread(id)
    where('parent_chain @> ARRAY[CAST(? AS BIGINT)]', id)
  end

  def destroy_parent_chain
    self.parent_chain = []
    save
  end

  def parent_chain
    self.parent_chain = [] if super.nil?
    super
  end

  def reparent_children
    # rubocop:disable Rails/SkipsModelValidations
    StreamPost.thread(id).update_all(['parent_chain = array_remove(parent_chain, CAST(? AS BIGINT))', id])
    # rubocop:enable Rails/SkipsModelValidations
  end

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s@-]/, '')
    limit_criteria(StreamPost.pg_search(search_text), params)
  end
end
