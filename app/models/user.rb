# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                    :bigint           not null, primary key
#  ban_reason            :string
#  current_location      :string
#  display_name          :string
#  email                 :string
#  home_location         :string
#  last_login            :datetime
#  last_photo_updated    :datetime         not null
#  last_viewed_alerts    :datetime
#  mute_reason           :string
#  mute_thread           :string
#  needs_password_change :boolean          default(FALSE), not null
#  password              :string
#  photo_hash            :string
#  pronouns              :string
#  real_name             :string
#  registration_code     :string
#  role                  :integer
#  room_number           :string
#  show_pronouns         :boolean          default(FALSE), not null
#  status                :string
#  username              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
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

    STRINGS = %w[banned muted user moderator tho admin].freeze

    def self.as_string(role)
      STRINGS[role]
    end

    def self.from_string(role_string)
      STRINGS.index(role_string)
    end
  end

  include Searchable

  MIN_AUTO_COMPLETE_LEN = 1
  AUTO_COMPLETE_LIMIT = 10

  USERNAME_CACHE_TIME = 30.minutes

  USERNAME_REGEX = /^\w{3,40}$/.freeze
  DISPLAY_NAME_REGEX = /^[\w. &-]{3,40}$/.freeze

  ACTIVE_STATUS = 'active'
  RESET_PASSWORD = 'seamonkey'

  # TODO: Create these as separate tables
  # field :pc, as: :personal_comments, type: Hash, default: {}

  has_many :stream_posts, inverse_of: :user, foreign_key: :author, dependent: :destroy
  has_many :forum_posts, inverse_of: :user, foreign_key: :author, dependent: :destroy
  has_many :announcements, inverse_of: :user, foreign_key: :author, dependent: :destroy
  has_many :post_reactions, inverse_of: :user, dependent: :destroy, class_name: 'PostReaction'
  has_many :forum_views, inverse_of: :user, dependent: :destroy, class_name: 'UserForumView'
  has_many :user_seamails, inverse_of: :user, dependent: :destroy
  has_many :seamails, through: :user_seamails
  has_many :seamail_messages, through: :seamails
  has_many :seamail_messages_authored, inverse_of: :user, foreign_key: :author, dependent: :destroy, class_name: 'SeamailMessage'
  has_many :user_stars, inverse_of: :user, dependent: :destroy, class_name: 'UserStar'
  has_many :starred_users, through: :user_stars
  has_many :starred_by_users, inverse_of: :starred_user, foreign_key: :starred_user_id, dependent: :destroy, class_name: 'UserStar'
  has_many :user_comments, inverse_of: :user, dependent: :destroy, class_name: 'UserComment'
  has_many :commented_by_users, inverse_of: :commented_user, foreign_key: :commented_user_id, dependent: :destroy, class_name: 'UserComment'
  has_many :user_events, inverse_of: :user, dependent: :destroy
  has_many :events, through: :user_events
  has_many :forums_last_poster, inverse_of: :last_post_user, foreign_key: :last_post_user_id, dependent: :nullify, class_name: 'Forum'

  after_save :update_cache_for_user

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
  validates :home_location, :real_name, :pronouns, length: { maximum: 100 }
  validates :room_number, allow_blank: true, length: { minimum: 4, maximum: 5 }

  pg_search_scope :pg_search,
                  against: [:username, :display_name, :real_name],
                  using: {
                    tsearch: { any_word: true, prefix: true }
                  }

  def valid_role?
    errors.add(:role, "Invalid role. Must be one of: #{User::Role::STRINGS * ', '}.") if role.nil? || User::Role.as_string(role).nil?
  end

  def valid_mute_reason?
    errors.add(:mute_reason, 'When user is muted, mute reason is required.') if role == User::Role::MUTED && mute_reason.blank?
  end

  def valid_ban_reason?
    errors.add(:ban_reason, 'When user is banned, ban reason is required.') if role == User::Role::BANNED && ban_reason.blank?
  end

  def self.valid_username?(username)
    return false unless username

    !username.match(USERNAME_REGEX).nil?
  end

  def valid_username?
    errors.add(:username, 'Username must be three to forty characters long, and can only include letters, numbers, and underscore.') unless User.valid_username?(username)
    errors.add :username, 'An account with this username already exists.' if new_record? && User.exists?(username: username)
  end

  def valid_password?
    errors.add :password, 'Your password must be at least six characters long.' if password.nil? || password.length < 6
    errors.add :password, 'Your password cannot be more than 100 characters long.' if !password.nil? && password.length > 100
  end

  def valid_registration_code?
    return true if Rails.configuration.disable_registration_codes

    errors.add(:registration_code, 'Invalid registration code.') if new_record? && (!RegistrationCode.valid_code?(registration_code) || User.exists?(registration_code: registration_code))
  end

  def self.valid_display_name?(name)
    return true unless name

    !name.match(DISPLAY_NAME_REGEX).nil?
  end

  def valid_display_name?
    errors.add(:display_name, 'If display name is entered, it must be three to forty characters long, and cannot include any of ~!@#$%^*()+=<>{}[]\\|;:/?') unless User.valid_display_name?(display_name)
  end

  def valid_location?
    Location.valid_location?(current_location)
  end

  def valid_room_number?
    errors.add(:room_number, 'Room number must be blank or an integer.') unless room_number.blank? || Integer(room_number)
  rescue StandardError
    false
  end

  def change_role(role_string)
    self.role = User::Role.from_string(role_string)
  end

  def change_password(pass)
    self.password = BCrypt::Password.create pass
    self.needs_password_change = pass == RESET_PASSWORD
  end

  def correct_password?(pass)
    BCrypt::Password.new(password) == pass
  end

  def update_last_login
    self.last_login = Time.zone.now
    self
  end

  def username=(val)
    super User.format_username val
  end

  def display_name=(val)
    super val&.strip
  end

  def real_name=(val)
    super val&.strip
  end

  def home_location=(val)
    super val&.strip
  end

  def registration_code=(val)
    super val.upcase.gsub(/[^A-Z0-9]/, '')
  end

  def upcoming_events(alerts = false, unnoticed = false)
    upcoming = user_events.includes(:event).references(:events)
                          .where('events.start_time >= ? AND events.start_time <= ? AND (events.end_time is null OR events.end_time <= ?)', Time.zone.now - 1.hour, Time.zone.now + 2.hours, Time.zone.now)

    if unnoticed
      upcoming = upcoming.where(acknowledged_alert: false)
    else
      upcoming = upcoming.order(start_time: :asc, title: :asc).limit(20)
      # rubocop:disable Rails/SkipsModelValidations
      upcoming.update_all(acknowledged_alert: true) if alerts
      # rubocop:enable Rails/SkipsModelValidations
    end

    upcoming.map(&:event)
  end

  def unnoticed_upcoming_events
    upcoming_events(false, true).count
  end

  def comment(commenting_user_id, comment)
    user_comment = commented_by_users.find_or_initialize_by(user_id: commenting_user_id)
    user_comment.comment = comment
    user_comment.save if user_comment.valid?
  end

  def seamail_threads(params = {})
    query = seamails
    query = query.where('seamails.last_update > ?', params[:after]) if params.key?(:after)

    if params.key?(:unread)
      query = query.includes(:seamail_messages).references(:seamail_messages).where('user_seamails.last_viewed is null OR seamail_messages.created_at > user_seamails.last_viewed')
      query = query.where('seamail_messages.created_at > ?', params[:after]) if params.key?(:after)
    end

    query.order(last_update: :desc)
  end

  def seamail_unread_count
    seamail_messages.where('seamail_messages.created_at > user_seamails.last_viewed').count
  end

  def seamail_count
    seamail_messages.count
  end

  def number_of_tweets
    stream_posts.count
  end

  def number_of_mentions
    StreamPost.where('mentions @> ?', "{#{username}}").count
  end

  def self.format_username(username)
    username&.downcase&.strip
  end

  def self.exist?(username)
    exists?(username: format_username(username))
  end

  def self.get(username)
    find_by(username: format_username(username))
  end

  def reset_photo
    result = PhotoStore.instance.reset_profile_photo username
    if result[:status] == 'ok'
      self.photo_hash = result[:md5_hash]
      self.last_photo_updated = Time.zone.now
      save
    end
    result
  end

  def update_photo(file)
    result = PhotoStore.instance.upload_profile_photo(file, username)
    if result[:status] == 'ok'
      self.photo_hash = result[:md5_hash]
      self.last_photo_updated = Time.zone.now
      save
    end
    result
  end

  def profile_picture_path
    path = PhotoStore.instance.small_profile_path(username)
    reset_photo unless File.exist? path
    path
  end

  def full_profile_picture_path
    path = PhotoStore.instance.full_profile_path(username)
    reset_photo unless File.exist? path
    path
  end

  def unnoticed_mentions
    @unnoticed_mentions ||= StreamPost.view_mentions(query: username, after: last_viewed_alerts, mentions_only: true).count +
                            Forum.view_mentions(query: username, after: last_viewed_alerts, mentions_only: true).count
  end

  def update_forum_view(forum_id)
    now = Time.zone.now

    # rubocop:disable Rails/SkipsModelValidations
    UserForumView.upsert({ user_id: id, forum_id: forum_id, last_viewed: now }, unique_by: [:user_id, :forum_id])
    # rubocop:enable Rails/SkipsModelValidations

    clear_forum_view_cache(forum_id, now)
  end

  def mark_all_forums_read(participated_only)
    query = Forum.unscoped.all
    query = query.includes(:posts).where(forum_posts: { author: id }).references(:forum_posts) if participated_only

    now = Time.zone.now
    timestamps = query.pluck(:id).map do |forum_id|
      clear_forum_view_cache(forum_id, now)
      { user_id: id, forum_id: forum_id, last_viewed: now }
    end
    # rubocop:disable Rails/SkipsModelValidations
    UserForumView.upsert_all(timestamps, unique_by: [:user_id, :forum_id])
    # rubocop:enable Rails/SkipsModelValidations
  end

  def clear_forum_view_cache(forum_id, now)
    Rails.cache.fetch("f:pcs:#{forum_id}:#{id}", force: true, expires_in: Forum::FORUM_CACHE_TIME) do
      0
    end
    Rails.cache.fetch("f:lv:#{forum_id}:#{id}", force: true, expires_in: Forum::FORUM_CACHE_TIME) do
      now
    end
  end

  def reset_last_viewed_alerts(time = Time.zone.now)
    self.last_viewed_alerts = time
  end

  def unnoticed_announcements
    @unnoticed_announcements ||= Announcement.new_announcements(last_viewed_alerts).count
  end

  def unnoticed_alerts
    @unnoticed_alerts ||= (unnoticed_mentions || 0).positive? || (seamail_unread_count || 0).positive? || unnoticed_announcements >= 1 || unnoticed_upcoming_events >= 1
  end

  def self.display_name_from_username(username)
    username = format_username(username)
    Rails.cache.fetch("dn:#{username}", expires_in: USERNAME_CACHE_TIME) do
      User.find_by(username: username).display_name
    end
  end

  def self.last_photo_updated_from_username(username)
    username = format_username(username)
    Rails.cache.fetch("lpu:#{username}", expires_in: USERNAME_CACHE_TIME) do
      User.find_by(username: username).last_photo_updated
    end
  end

  def update_cache_for_user
    Rails.cache.fetch("dn:#{username}", force: true, expires_in: USERNAME_CACHE_TIME) do
      display_name
    end
    Rails.cache.fetch("lpu:#{username}", force: true, expires_in: USERNAME_CACHE_TIME) do
      last_photo_updated
    end
  end

  def last_forum_view(forum_id)
    ts = forum_view_timestamps.find_by(forum_id: forum_id)
    ts ? ts.view_time : Time.zone.local(0)
  end

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s-]/, '')
    limit_criteria(User.pg_search(search_text), params)
  end

  def self.auto_complete(query)
    query += '%'
    User.where('username like ? or display_name like ?', query, query).limit(AUTO_COMPLETE_LIMIT)
  end

  def process_role_change(old_role, new_role, current_username)
    # Handle access to moderator seamail message
    if old_role < Role::MODERATOR && new_role >= Role::MODERATOR
      # Scenario 1: User has been promoted to moderator or above - grant access to moderation thread
      user_seamails.find_or_create_by(seamail_id: 1)
    elsif old_role >= Role::MODERATOR && new_role < Role::MODERATOR
      # Scenario 2: User has been demoted from moderator or above - remove access to modeartion thread
      seamail = user_seamails.find_by(seamail_id: 1)
      user_seamails.delete(seamail) if seamail
    end

    # Handle sending of muted/unmuted seamail
    send_muted_message(current_username) if new_role == User::Role::MUTED && old_role != User::Role::MUTED
    send_unmuted_message(current_username) if new_role >= User::Role::USER && old_role == User::Role::MUTED
  end

  def send_muted_message(current_username)
    subject = 'You have been muted'
    message = <<~MESSAGE
      Hello #{username},

      This is an automated message letting you know that you have been muted. While you are muted, you will be unable to make any posts, send any seamail, or update your profile. It is likely that this muting is temporary, especially if this is the first time you have been muted.

      You may be wondering why this has happened. Maybe a post you made was in violation of the Code of Conduct. Maybe a moderator thinks a thread was getting out of hand, and is doing some clean-up. Whatever the reason, it's not personal, it's just a moderator doing what they think best for the overall health of Twit-arr.

      When muting happens, the moderator is required to enter a reason. Here is the reason that was provided for your mute:

      #{mute_reason}

      A moderator may also send you additional seamail (either in this thread or a new thread) if they would like to provide you with more information. If you would like to discuss this with someone, please proceed to the info desk. They will be able to put you in touch with someone from the moderation team.

      Bleep bloop,
      The Twit-arr Robot
    MESSAGE

    begin
      seamail = Seamail.find(mute_thread)
      seamail.add_message 'moderator', message, current_username
    rescue StandardError
      seamail = Seamail.create_new_seamail 'moderator', [username], subject, message, current_username
      self.mute_thread = seamail.id.to_s
      save
    end
  end

  def send_unmuted_message(current_username)
    message = <<~MESSAGE
      Hello #{username},

      Good news! You have been unmuted. Please continue to enjoy your Twit-arr experience!

      Bleep bloop,
      The Twit-arr Robot
    MESSAGE

    begin
      seamail = Seamail.find(mute_thread)
    rescue StandardError
      subject = 'You have been unmuted'
      seamail = Seamail.create_new_seamail 'moderator', [username], subject, message, current_username
      self.mute_thread = seamail.id.to_s
      save
    end
    seamail.add_message 'moderator', message, current_username
  end

  def self.create_default_users
    unless User.exist? 'twitarrteam'
      user = User.new username: 'twitarrteam', display_name: 'TwitarrTeam', password: Rails.application.secrets.initial_admin_password,
                      role: User::Role::ADMIN, status: User::ACTIVE_STATUS, registration_code: 'code1'
      user.change_password user.password
      user.save
    end

    unless User.exist? 'official'
      user = User.new username: 'official', display_name: 'official', password: SecureRandom.hex,
                      role: User::Role::THO, status: User::ACTIVE_STATUS, registration_code: 'code2'
      user.change_password user.password
      user.save
    end

    unless User.exist? 'moderator' # rubocop:disable Style/GuardClause
      user = User.new username: 'moderator', display_name: 'moderator', password: Rails.application.secrets.initial_admin_password,
                      role: User::Role::MODERATOR, status: User::ACTIVE_STATUS, registration_code: 'code3'
      user.change_password user.password
      user.save
    end
  end

  def self.all_user_ids(update = false)
    Rails.cache.fetch('user:all_ids', force: update, expires_in: User::USERNAME_CACHE_TIME) do
      User.all.pluck(:id)
    end
  end
end
