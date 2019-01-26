require 'bcrypt'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Searchable

  MIN_AUTO_COMPLETE_LEN = 1
  AUTO_COMPLETE_LIMIT = 10

  USERNAME_CACHE_TIME = 30.minutes

  USERNAME_REGEX = /^[\w&-]{3,}$/
  DISPLAY_NAME_REGEX = /^[\w\. &-]{3,40}$/

  ACTIVE_STATUS = 'active'
  RESET_PASSWORD = 'seamonkey'

  field :un, as: :username, type: String
  field :pw, as: :password, type: String
  field :ia, as: :is_admin, type: Boolean
  field :st, as: :status, type: String
  field :em, as: :email, type: String
  field :dn, as: :display_name, type: String
  field :ll, as: :last_login, type: Time, default: Time.at(0)
  field :um, as: :unnoticed_mentions, type: Integer, default: 0
  field :al, as: :last_viewed_alerts, type: Time, default: Time.at(0)
  field :ph, as: :photo_hash, type: String
  field :pu, as: :last_photo_updated, type: Time, default: Time.now
  field :rn, as: :room_number, type: String
  field :an, as: :real_name, type: String
  field :hl, as: :home_location, type: String
  field :lf, as: :forum_view_timestamps, type: Hash, default: {}
  field :lc, as: :current_location, type: String
  field :us, as: :starred_users, type: Array, default: []
  field :pc, as: :personal_comments, type: Hash, default: {}
  field :ea, as: :acknowledged_event_alerts, type: Array, default: []
  field :rc, as: :registration_code, type: String
  field :pr, as: :pronouns, type: String

  index username: 1
  index display_name: 1
  index :display_name => 'text'

  # noinspection RubyResolve
  after_save :update_display_name_cache

  validate :valid_registration_code?
  validate :valid_username?
  validate :valid_display_name?
  validate :valid_location?
  validates :email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: 'E-mail address is not valid.' }
  validate :valid_password?
  
  def self.valid_username?(username)
    return false unless username
    !username.match(USERNAME_REGEX).nil?
  end

  def valid_username?
    unless User.valid_username?(username)
      errors.add(:username, 'Username must be three or more characters and only include letters, numbers, underscore, dash, and ampersand.')
    end
    if new_record? && User.where(username: username).exists?
      errors.add :username, 'An account with this username already exists.'
    end
  end

  def valid_password?
    if password.nil? || password.length < 6
      errors.add :password, 'Your password must be at least six characters long.'
    end
  end

  def valid_registration_code?
    if new_record? && !RegistrationCode.valid_code?(registration_code)
      errors.add(:registration_code, 'Invalid registration code.')
    end
  end

  def self.valid_display_name?(name)
    return true unless name
    !name.match(DISPLAY_NAME_REGEX).nil?
  end

  def valid_display_name?
    unless User.valid_display_name? (display_name)
      errors.add(:display_name, 'If display name is entered, it must be three or more characters and cannot include any of ~!@#$%^*()+=<>{}[]\\|;:/?')
    end
  end

  def valid_location?
    user_location = self[:current_location]
    Location.valid_location? user_location
  end

  def empty_password?
    password.nil? || password.empty?
  end

  def set_password(pass)
    self.password = BCrypt::Password.create pass
  end

  def correct_password(pass)
    BCrypt::Password.new(password) == pass
  end

  def update_last_login
    self.last_login = Time.now
    self
  end

  def username=(val)
    super User.format_username val
  end

  def current_location=(loc)
    super loc
  end

  def display_name=(val)
    super val.andand.strip
  end

  def room_number=(val)
    if val.nil? || val.empty? || (val.is_a? Numeric)
      return super val
    else
      if val.andand.strip.to_i > 0
        return super val.andand.strip.to_i
      else
        return nil
      end
    end
  end

  def real_name=(val)
    super val.andand.strip
  end

  def home_location=(val)
    super val.andand.strip
  end

  def upcoming_events(alerts=false)
    events = Event.where(:start_time.gte => (DateTime.now - 1.hours)).where(:start_time.lte => (DateTime.now + 3.hours)).limit(20).order_by(:start_time.desc)
    events = events.map {|x| x if !x.end_time or x.end_time > DateTime.now }.compact
    events = events.map { |x| x if x.favorites.include? self.username }.compact
    if alerts
      events = events.map { |e| e unless self.acknowledged_event_alerts.include? e.id }.compact
      events.each { |e| self.acknowledged_event_alerts << e.id unless self.acknowledged_event_alerts.include? e.id }
      self.save
    end
    events
  end

  def unnoticed_upcoming_events
    events = self.upcoming_events()
    events = events.map {|e| e unless self.acknowledged_event_alerts.include? e.id}.compact
    events.count
  end

  def seamails(params = {})
    threadQuery = Hash.new
    threadQuery["us"] = username
    threadQuery["up"] = { "$gt" => params[:after]} if params.has_key?(:after)

    postQuery = Hash.new
    postQuery["sm.rd"] = {"$ne" => username } if params.has_key?(:unread)
    postQuery["sm.ts"] = {"$gt" => params[:after]} if params.has_key?(:after)

    aggregation = Array.new
    aggregation.push({"$match" => threadQuery})
    aggregation.push({"$unwind" => "$sm"})

    if postQuery.length > 0
      aggregation.push({"$match" => postQuery})
    end

    aggregation.push({"$sort" => { "sm.ts" => -1 }})
    aggregation.push({
      "$group" => {
        "_id" => "$_id",
        "deleted_at" => { "$first" => "$deleted_at" },
        "us" => { "$first" => "$us" },
        "sj" => { "$first" => "$sj" },
        "up" => { "$first" => "$up" },
        "updated_at" => { "$first" => "$updated_at" },
        "created_at" => { "$first" => "$created_at" },
        "sm" => { "$push" => "$sm" }
      }
    })

    result = Seamail.collection.aggregate(aggregation).map { |x| Seamail.new(x) { |o| o.new_record = false } }

    result.sort_by { |x| x.last_message }.reverse
  end

  def seamail_unread_count
    Seamail.collection.aggregate([
      {
        "$match" => { "us" => username }
      },
      {
        "$unwind" => "$sm"
      },
      {
        "$match" => { "sm.rd" => {"$ne" => username } }
      },
      {
        "$group" => {
          "_id" => "$_id"
        }
      }
    ]).count
  end

  def seamail_count
    Seamail.where(usernames: username).length
  end

  def number_of_tweets
    StreamPost.where(author: self.username).count
  end

  def number_of_mentions
    StreamPost.where(mentions: self.username).count
  end

  def self.format_username(username)
    username.andand.downcase.andand.strip
  end

  def self.exist?(username)
    where(username: format_username(username)).exists?
  end

  def self.get(username)
    where(username: format_username(username)).first
  end

  def reset_photo
    result = PhotoStore.instance.reset_profile_photo username
    if result[:status] == 'ok'
      self.photo_hash = result[:md5_hash]
      self.last_photo_updated = Time.now
      save
    end
    result
  end

  def update_photo(file)
    result = PhotoStore.instance.upload_profile_photo(file, username)
    if result[:status] == 'ok'
      self.photo_hash = result[:md5_hash]
      self.last_photo_updated = Time.now
      save
    end
    result
  end

  def profile_picture_path
    path = PhotoStore.instance.small_profile_path(username)
    reset_photo unless File.exists? path
    path
  end

  def full_profile_picture_path
    path = PhotoStore.instance.full_profile_path(username)
    reset_photo unless File.exists? path
    path
  end

  def inc_mentions
    inc(unnoticed_mentions: 1)
  end

  def self.inc_mentions(username)
    User.find_by(username: username).inc(unnoticed_mentions: 1)
  end

  def reset_mentions
    set(unnoticed_mentions: 0)
  end

  def update_forum_view(forum_id)
    self.forum_view_timestamps[forum_id] = Time.now
    save
  end

  def reset_last_viewed_alerts
    reset_mentions
    self.last_viewed_alerts = DateTime.now
  end

  def unnoticed_announcements
    Announcement.new_announcements(last_viewed_alerts).count
  end

  def unnoticed_alerts
    (unnoticed_mentions || 0) > 0 || (seamail_unread_count || 0) > 0 || unnoticed_announcements >= 1 || unnoticed_upcoming_events >= 1
  end

  def self.display_name_from_username(username)
    Rails.cache.fetch("display_name:#{username}", expires_in: USERNAME_CACHE_TIME) do
      User.where(username: username).only(:display_name).map(:display_name).first
    end
  end

  def self.last_photo_updated_from_username(username)
    Rails.cache.fetch("last_photo_updated:#{username}", expires_in: 5.minutes) do
      User.where(username: username).only(:last_photo_updated).map(:last_photo_updated).first
    end
  end

  def update_display_name_cache
    Rails.cache.fetch("display_name:#{username}", force: true, expires_in: USERNAME_CACHE_TIME ) do
      display_name
    end
  end

  def last_forum_view(forum_id)
    self.forum_view_timestamps[forum_id] || Time.new(0)
  end

  def self.search(params = {})
    query = params[:query].strip.downcase.gsub(/[^\w&\s-]/, '')
    criteria = User.or({:username => /^#{query}.*/i}, { :display_name => /^#{query}.*/i }, { '$text' => { '$search' => "\"#{query}\"" } })
    limit_criteria(criteria, params)
  end

  def self.auto_complete(query)
    User.or(
      { username: /^#{query}/ },
      { display_name: /^#{query}/i },
    ).limit(AUTO_COMPLETE_LIMIT)
  end
end
