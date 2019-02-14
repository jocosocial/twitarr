class ForumPost
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Searchable
  include Postable

  # Common fields between stream_post and forum_post
  field :au, as: :author, type: String
  field :oa, as: :original_author, type: String, default: ->{author}
  field :tx, as: :text, type: String
  field :ts, as: :timestamp, type: Time
  field :ht, as: :hash_tags, type: Array
  field :mn, as: :mentions, type: Array
  field :et, as: :entities, type: Array

  field :ph, as: :photos, type: Array

  embeds_many :reactions, class_name: 'PostReaction', store_as: :rn, order: :reaction.asc, validate: true

  embedded_in :forum, inverse_of: :posts

  validates :author, :timestamp, presence: true
  validates :text, presence: true, length: {maximum: 10000}
  validate :validate_author
  validate :validate_original_author
  validate :validate_photos

  before_validation :parse_hash_tags
  after_create :post_create_operations

  def photos
    self.photos = [] if super.nil?
    super
  end

  def validate_photos
    return if photos.count == 0
    photos.each do |photo|
      unless PhotoMetadata.exist? photo
        errors[:base] << "#{photo} is not a valid photo id"
      end
    end
  end

end
