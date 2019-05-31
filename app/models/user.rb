# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  username           :string
#  password           :string
#  role               :integer
#  status             :string
#  email              :string
#  display_name       :string
#  last_login         :datetime
#  last_viewed_alerts :datetime
#  photo_hash         :string
#  last_photo_updated :datetime         not null
#  room_number        :string
#  real_name          :string
#  home_location      :string
#  current_location   :string
#  registration_code  :string
#  pronouns           :string
#  mute_reason        :string
#  ban_reason         :string
#  mute_thread        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_users_on_display_name       (display_name)
#  index_users_on_registration_code  (registration_code) UNIQUE
#  index_users_on_username           (username) UNIQUE
#

require 'bcrypt'

class User < ApplicationRecord

  class Role
    ADMIN = 5
    THO = 4
    MODERATOR = 3
    USER = 2
    MUTED = 1
    BANNED = 0

    STRINGS = %w(banned muted user moderator tho admin)

    def self.as_string(role)
      return STRINGS[role]
    end

    def self.from_string(role_string)
      return STRINGS.index(role_string)
    end
  end

  include Searchable

  MIN_AUTO_COMPLETE_LEN = 1
  AUTO_COMPLETE_LIMIT = 10

  USERNAME_CACHE_TIME = 30.minutes

  USERNAME_REGEX = /^[\w]{3,40}$/
  DISPLAY_NAME_REGEX = /^[\w\. &-]{3,40}$/

  ACTIVE_STATUS = 'active'
  RESET_PASSWORD = 'seamonkey'

  # TODO: Create these as separate tables
  # field :lf, as: :forum_view_timestamps, type: Hash, default: {}
  # field :us, as: :starred_users, type: Array, default: []
  # field :pc, as: :personal_comments, type: Hash, default: {}
  # field :ea, as: :acknowledged_event_alerts, type: Array, default: []

  # noinspection RubyResolve
  after_save :update_display_name_cache

  validate :valid_role?
  validate :valid_mute_reason?
  validate :valid_ban_reason?
  validate :valid_registration_code?
  validate :valid_username?
  validate :valid_display_name?
  validate :valid_location?
  validates :email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: 'E-mail address is not valid.' }
  validate :valid_password?
  validate :valid_room_number?
  validates :home_location, :real_name, :pronouns, length: {maximum: 100}
  validates :room_number, allow_blank: true, length: {minimum: 4, maximum: 5}

  def valid_role?
    if role.nil? || User::Role.as_string(role).nil?
      errors.add(:role, "Invalid role. Must be one of: #{User::Role::STRINGS*", "}.")
    end
  end

  def valid_mute_reason?
    if role == User::Role::MUTED && (mute_reason.nil? || mute_reason.empty?)
      errors.add(:mute_reason, "When user is muted, mute reason is required.")
    end
  end

  def valid_ban_reason?
    if role == User::Role::BANNED && (ban_reason.nil? || ban_reason.empty?)
      errors.add(:ban_reason, "When user is banned, ban reason is required.")
    end
  end

  def self.valid_username?(username)
    return false unless username
    !username.match(USERNAME_REGEX).nil?
  end

  def valid_username?
    unless User.valid_username?(username)
      errors.add(:username, 'Username must be three to forty characters long, and can only include letters, numbers, and underscore.')
    end
    if new_record? && User.where(username: username).exists?
      errors.add :username, 'An account with this username already exists.'
    end
  end

  def valid_password?
    if password.nil? || password.length < 6
      errors.add :password, 'Your password must be at least six characters long.'
    end
    if password.length > 100
      errors.add :password, 'Your password cannot be more than 100 characters long.'
    end
  end

  def valid_registration_code?
    return true if Rails.env.downcase == 'test'

    if new_record? && (!RegistrationCode.valid_code?(registration_code) || User.where(registration_code: registration_code).exists?)
      errors.add(:registration_code, 'Invalid registration code.')
    end
  end

  def self.valid_display_name?(name)
    return true unless name
    !name.match(DISPLAY_NAME_REGEX).nil?
  end

  def valid_display_name?
    unless User.valid_display_name? (display_name)
      errors.add(:display_name, 'If display name is entered, it must be three to forty characters long, and cannot include any of ~!@#$%^*()+=<>{}[]\\|;:/?')
    end
  end

  def valid_location?
    user_location = self[:current_location]
    Location.valid_location? user_location
  end

  def valid_room_number?
    unless self[:room_number].nil? || self[:room_number].empty? || (Integer(self[:room_number]) rescue false)
      errors.add(:room_number, 'Room number must be blank or an integer.')
    end
  end

  def set_role(role_string)
    self.role = User::Role.from_string(role_string)
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

  def real_name=(val)
    super val.andand.strip
  end

  def home_location=(val)
    super val.andand.strip
  end

  def registration_code=(val)
    super val.upcase.gsub(/[^A-Z0-9]/, "")
  end

  def upcoming_events(alerts=false)
    events = Event.where(:start_time.gte => (Time.now - 1.hours)).where(:start_time.lte => (Time.now + 2.hours)).limit(20).order_by(:start_time.asc)
    events = events.map {|x| x if !x.end_time or x.end_time <= Time.now }.compact
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

  def unnoticed_mentions
    StreamPost.view_mentions(query: self.username, after: self.last_viewed_alerts, mentions_only: true).count +
      Forum.view_mentions(query: self.username, after: self.last_viewed_alerts, mentions_only: true).count
  end

  def update_forum_view(forum_id)
    self.forum_view_timestamps[forum_id] = Time.now
    save
  end

  def mark_all_forums_read(participated_only)
    if participated_only
      query = Forum.where(:'fp.au' => self.username).all
    else
      query = Forum.all
    end

    now = Time.now
    hash = Hash.new
    query.pluck(:id).each{|x| hash[x.to_s] = now}
    self.forum_view_timestamps = hash
    save
  end

  def reset_last_viewed_alerts(time = Time.now)
    self.last_viewed_alerts = time
  end

  def unnoticed_announcements
    Announcement.new_announcements(last_viewed_alerts).count
  end

  def unnoticed_alerts
    (unnoticed_mentions || 0) > 0 || (seamail_unread_count || 0) > 0 || unnoticed_announcements >= 1 || unnoticed_upcoming_events >= 1
  end

  def self.display_name_from_username(username)
    username = format_username(username)
    Rails.cache.fetch("display_name:#{username}", expires_in: USERNAME_CACHE_TIME) do
      User.where(username: username).only(:display_name).map(:display_name).first
    end
  end

  def self.last_photo_updated_from_username(username)
    username = format_username(username)
    Rails.cache.fetch("last_photo_updated:#{username}", expires_in: USERNAME_CACHE_TIME) do
      User.where(username: username).only(:last_photo_updated).map(:last_photo_updated).first
    end
  end

  def update_display_name_cache
    Rails.cache.fetch("display_name:#{username}", force: true, expires_in: USERNAME_CACHE_TIME) do
      display_name
    end
    Rails.cache.fetch("last_photo_updated:#{username}", force: true, expires_in: USERNAME_CACHE_TIME) do
      last_photo_updated
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
