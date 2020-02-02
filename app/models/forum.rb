# == Schema Information
#
# Table name: forums
#
#  id                :bigint           not null, primary key
#  forum_posts_count :integer          default(0), not null
#  last_post_time    :datetime         not null
#  locked            :boolean          default(FALSE), not null
#  sticky            :boolean          default(FALSE), not null
#  subject           :string           not null
#  last_post_user_id :bigint
#
# Indexes
#
#  index_forums_on_sticky_and_last_post_time  (sticky,last_post_time)
#  index_forums_subject                       (to_tsvector('english'::regconfig, (subject)::text)) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (last_post_user_id => users.id)
#

class Forum < ApplicationRecord
  include Searchable

  PAGE_SIZE = 20
  FORUM_CACHE_TIME = 30.minutes

  has_many :posts, -> { order(:created_at) }, class_name: 'ForumPost', dependent: :destroy, inverse_of: :forum, validate: false
  has_many :users, through: :posts
  belongs_to :last_post_user, class_name: 'User', foreign_key: :last_post_user_id, inverse_of: :forums_last_poster

  validates :subject, presence: true, length: { maximum: 200 }
  validate :validate_posts

  default_scope { includes(:last_post_user).references(:last_post_user) }

  pg_search_scope :pg_search,
                  against: :subject,
                  associated_against: { posts: :text },
                  using: {
                      trigram: { word_similarity: true },
                      tsearch: { any_word: true, prefix: true }
                  }

  def validate_posts
    errors[:base] << 'Must have a post' if posts.empty?
    posts.each do |post|
      post.errors.full_messages.each { |x| errors[:base] << x } unless post.valid?
    end
  end

  def subject=(subject)
    super subject&.strip
  end

  def last_post
    posts.includes(:user).order(:created_at).last
  end

  def update_cache
    post = last_post
    if last_post
      Rails.cache.delete_matched("forum:post_count_since:#{post.forum_id}:.*")
      update(last_post_time: post.created_at, last_post_user_id: post.author)
    else
      destroy
    end
  end

  def post_count_since_last_visit(user)
    timestamp = user.forum_last_view(id)
    if timestamp
      Rails.cache.fetch("forum:post_count_since:#{id}:#{user.id}", expires_in: Forum::FORUM_CACHE_TIME) do
        posts.where('forum_posts.created_at > ?', timestamp).count
      end
    else
      forum_posts_count
    end
  end

  def self.create_new_forum(author, subject, first_post_text, photos, original_author)
    forum = Forum.new(subject: subject)
    post = ForumPost.new(author: author, text: first_post_text, original_author: original_author)
    photos&.each do |photo|
      post.post_photos << PostPhoto.new(photo_metadata_id: photo)
    end
    forum.posts << post
    forum.save if forum.valid?
    forum
  end

  def add_post(author, text, photos, original_author)
    post = ForumPost.new(author: author, text: text, original_author: original_author)
    photos&.each do |photo|
      post.post_photos << PostPhoto.new(photo_metadata_id: photo)
    end
    posts << post
    post
  end

  def self.view_mentions(params = {})
    query_string = params[:query]
    start_loc = params[:page] || 0
    limit = params[:limit] || 20
    query = includes(:posts).references(:forum_posts)
    query = if params[:mentions_only]
              query.where('forum_posts.mentions @> ?', "{#{query_string}}")
            else
              user_id = User.find_by_username(query_string).id
              query.where('forum_posts.mentions @> ? or forum_posts.author = ?', "{#{query_string}}", user_id)
            end
    if params[:after]
      val = Time.from_param(params[:after])
      query = query.where('forum_posts.created_at > ?', val) if val
    end
    query.order(id: :desc).offset(start_loc * limit).limit(limit)
  end

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s@-]/, '')
    limit_criteria(Forum.pg_search(search_text), params)
  end
end
