# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id          :uuid             not null, primary key
#  description :string
#  end_time    :datetime
#  location    :string
#  official    :boolean
#  start_time  :datetime         not null
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_events_on_official                 (official)
#  index_events_on_start_time_and_end_time  (start_time,end_time)
#  index_events_on_title                    (title)
#  index_events_search_desc                 (to_tsvector('english'::regconfig, (description)::text)) USING gin
#  index_events_search_loc                  (to_tsvector('english'::regconfig, (location)::text)) USING gin
#  index_events_search_title                (to_tsvector('english'::regconfig, (title)::text)) USING gin
#

class Event < ApplicationRecord
  include Searchable

  has_many :user_events, inverse_of: :event, dependent: :destroy

  pg_search_scope :pg_search,
                  against: [:description, :location, :title],
                  using: {
                    tsearch: { any_word: true, prefix: true }
                  }

  default_scope { order(start_time: :asc, title: :asc) }

  DST_START = Rails.configuration.dst_start

  # TODO: migrate
  # field :fa, as: :favorites, type: Array, default: []

  validates :title, :start_time, presence: true

  def self.search(params = {})
    search_text = params[:query].strip.downcase.gsub(/[^\w&\s@-]/, '')
    limit_criteria(Event.pg_search(search_text), params)
  end

  def self.create_new_event(_author, title, start_time, options = {})
    event = Event.new(title:, start_time:)
    event.description = options[:description] unless options[:description].nil?
    event.location = options[:location] unless options[:location].nil?
    event.official = options[:official] unless options[:official].nil?
    # Time.parse should occur on the controller side, but I haven't got time to straighten this out right now
    event.end_time = Time.zone.parse(options[:end_time]) unless options[:end_time].nil?
    event
  end

  def self.create_from_ics(ics_event)
    event = Event.find_or_initialize_by(id: ics_event.uid)

    event.title = ics_event.summary.force_encoding('utf-8')
    event.description = ics_event.description.force_encoding('utf-8')
    event.start_time = ics_event.dtstart
    event.end_time = ics_event.dtend unless ics_event.dtend.nil?
    # if ics_event.dtstart <= DST_START
    #  event.start_time = ics_event.dtstart
    #  event.end_time = ics_event.dtend
    # else
    #  event.start_time = ics_event.dtstart
    #  event.end_time = ics_event.dtend unless ics_event.dtend.nil?
    # end
    event.official = ics_event.categories.exclude?('SHADOW CRUISE')
    # locations tend to have trailing commas for some reason
    event.location = ics_event.location.force_encoding('utf-8').strip.gsub(/,$/, '')
    event.save
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.favorite_from_ics(ics_event, user_id)
    uid = ics_event.uid.split('@')[0]
    event = Event.find_by(id: uid)

    return unless event

    event.user_events.find_or_create_by(user_id:)
  end

  def follow(user_id)
    user_events.find_or_create_by(user_id:)
  end

  def unfollow(user_id)
    doc = user_events.find_by(user_id:)
    user_events.delete(doc) if doc
  end
end
