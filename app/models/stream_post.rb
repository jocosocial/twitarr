# noinspection RubyStringKeysInHashInspection
class StreamPost
  include Mongoid::Document
  include Twitter::Extractor

  field :au, as: :author, type: String
  field :tx, as: :text, type: String
  field :ts, as: :timestamp, type: Time
  field :p, as: :photo, type: String
  field :lk, as: :likes, type: Array, default: []
  field :ht, as: :hash_tags, type: Array
  field :mn, as: :mentions, type: Array
  field :et, as: :entities, type: Array
  field :pc, as: :parent_chain, type: Array, default: []

  validates :text, :author, :timestamp, presence: true
  validate :validate_author

  # 1 = ASC, -1 DESC
  index likes: 1
  index timestamp: -1
  index author: 1
  index mentions: 1
  index hash_tags: 1
  index parent_chain: 1
  index text: 'text'

  before_validation :parse_hash_tags
  after_create :post_create_operations

  def validate_author
    return if author.blank?
    unless User.exist? author
      errors[:base] << "#{author} is not a valid username"
    end
  end

  def add_like(username)
    StreamPost.
        where(id: id).
        find_and_modify({ '$addToSet' => { lk: username } }, new: true)
  end

  def remove_like(username)
    StreamPost.
        where(id: id).
        find_and_modify({ '$pull' => { lk: username } }, new: true)
  end

  def self.at_or_before(ms_since_epoch, filter_author = nil)
    query = where(:timestamp.lte => Time.at(ms_since_epoch.to_i / 1000.0))
    query = query.where(:author => filter_author) if filter_author
    query
  end

  def self.at_or_after(ms_since_epoch, filter_author = nil)
    query = where(:timestamp.gte => Time.at(ms_since_epoch.to_i / 1000.0))
    query = query.where(:author => filter_author) if filter_author
    query
  end

  # noinspection RubyResolve
  def parse_hash_tags
    self.entities = extract_entities_with_indices text
    self.hash_tags = []
    self.mentions = []
    entities.each do |entity|
      if entity.has_key? :hashtag
        self.hash_tags << entity[:hashtag]
      elsif entity.has_key? :screen_name
        self.mentions << entity[:screen_name]
      end
    end
  end

  def likes
    self.likes = [] if super.nil?
    super
  end

  def parent_chain
    self.parent_chain = [] if super.nil?
    super
  end

  def post_create_operations
    increment_mentions_counts
    record_hashtags
  end

  def increment_mentions_counts
    unknown_users = []
    self.mentions.each { |mentioned_user|
      begin
        User.inc_mentions mentioned_user
      rescue Mongoid::Errors::DocumentNotFound => e
        unknown_users.push mentioned_user
      rescue => e
        logger.info "Unable to increment mention for user: #{mentioned_user}: #{e.class.name}: #{e.message}"
      end
    }
    logger.info "Unable to find mentioned user(s) #{unknown_users.join ','} to increment mention count" unless unknown_users.empty?
  end

  def self.view_mentions(params = {})
    query_string = params[:query]
    start_loc = params[:page] || 0
    limit = params[:limit] || 20
    query = if params[:mentions_only]
      StreamPost.where({mentions: query_string})
    else
      StreamPost.or({mentions: query_string}, {author: query_string})
    end
    if params[:after]
      query = query.where(:timestamp.gt => params[:after])
    end
    query.order_by(timestamp: :desc).skip(start_loc*limit).limit(limit)
  end

  def record_hashtags
    self.hash_tags.each do |ht|
      Hashtag.add_tag ht
    end
  end

end