# == Schema Information
#
# Table name: forums
#
#  id             :bigint           not null, primary key
#  subject        :string           not null
#  last_post_time :datetime         not null
#  sticky         :boolean          default(FALSE), not null
#  locked         :boolean          default(FALSE), not null
#
# Indexes
#
#  index_forums_on_sticky_and_last_post_time  (sticky,last_post_time)
#  index_forums_subject                       (to_tsvector('english'::regconfig, (subject)::text)) USING gin
#

class Forum < ApplicationRecord
  include Searchable

  PAGE_SIZE = 20

  has_many :posts, class_name: 'ForumPost', dependent: :destroy

  validates :subject, presence: true, length: { maximum: 200 }
  validate :validate_posts

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
    posts.last.timestamp
  end

  def post_count
    posts.size
  end

  def post_count_since(timestamp)
    posts.select { |x| x.ts > timestamp }.count
  end

  def created_by
    posts.first.author
  end

  def self.create_new_forum(author, subject, first_post_text, _photos, original_author)
    forum = Forum.new(subject: subject)
    # forum.last_post_time = Time.now
    # binding.pry
    forum.posts << ForumPost.new(author: author, text: first_post_text, original_author: original_author)
    forum.save if forum.valid?
    forum
  end

  # This is just a terrible scheme
  def add_post(author, text, _photos, original_author)
    self.last_post_time = Time.now
    posts.create author: author, text: text, original_author: original_author
  end

  def self.view_mentions(params = {})
    query_string = params[:query]
    start_loc = params[:page] || 0
    limit = params[:limit] || 20
    queryParams = Hash.new
    queryParams[:mn] = query_string
    if params[:after]
      val = Time.from_param(params[:after])
      queryParams[:ts] = { '$gt' => val } if val
    end
    query = where(posts: { '$elemMatch' => queryParams }).order_by(id: :desc).skip(start_loc * limit).limit(limit)
  end

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s@-]/, '')
    criteria = Forum.or({ 'fp.au': /^#{search_text}.*/i }, '$text' => { '$search' => "\"#{search_text}\"" })
    limit_criteria(criteria, params)
  end
end
