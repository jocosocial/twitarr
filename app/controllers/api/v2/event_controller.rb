require 'csv'
class API::V2::EventController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_action :events_enabled
  before_action :login_required, :only => [:follow, :unfollow, :mine]
  before_action :admin_required, :only => [:destroy, :update]
  before_action :fetch_event, :only => [:update, :destroy, :ical, :follow, :unfollow, :show]

  def update
    @event.title = params[:title] if params.has_key? :title
    @event.description = params[:description] if params.has_key? :description
    @event.location = params[:location] if params.has_key? :location
    @event.start_time = Time.from_param(params[:start_time]) if params.has_key? :start_time
    @event.end_time = Time.from_param(params[:end_time]) if params.has_key? :end_time

    if @event.valid?
      @event.save
      render json: {status: 'ok', event: @event.decorate.to_hash(current_username, request_options)}
    else
      render status: :bad_request, json: {status: 'error', errors: @event.errors.full_messages}
    end
  end

  def destroy
    if @event.destroy
      render json: {status: 'ok'}
    else
      render status: :bad_request, json: {status: 'error', error: @event.errors}
    end
  end

  def ical
    # Yes this is based off vcard. They're really similar!
    cal_string = "BEGIN:VCALENDAR\n"
    cal_string << "VERSION:2.0\n"
    cal_string << "PRODID:-//twitarrteam/twitarr//NONSGML v1.0//END\n"

    cal_string << "BEGIN:VEVENT\n"
    cal_string << "UID:#{@event.id}@twitarr.local\n"
    cal_string << "DTSTAMP:#{@event.start_time.strftime('%Y%m%dT%H%M%S')}\n"
    cal_string << "ORGANIZER:CN=JOCO Cruise\n"
    cal_string << "DTSTART:#{@event.start_time.strftime('%Y%m%dT%H%M%S')}\n"
    cal_string << "DTEND:#{@event.end_time.strftime('%Y%m%dT%H%M%S')}\n" unless @event.end_time.blank?
    cal_string << "SUMMARY:#{@event.title}\n"
    cal_string << "DESCRIPTION:#{@event.description}\n"
    cal_string << "LOCATION:#{@event.location}\n"
    cal_string << "END:VEVENT\n"

    cal_string << "END:VCALENDAR"
    headers['Content-Disposition'] = "inline; filename=\"#{@event.title.parameterize('_')}.ics\""

    render body: cal_string, content_type: 'text/vcard', layout: false
  end

  def follow
    @event.follow current_username
    if @event.save
      render json: {status: 'ok', event: @event.decorate.to_hash(current_username, request_options)}
    else
      render status: :bad_request, json: {status: 'error', error: 'Unable to follow event.'}
    end
  end

  def unfollow
    @event.unfollow current_username
    if @event.save
      render json: {status: 'ok', event: @event.decorate.to_hash(current_username, request_options)}
    else
      render :bad_request, json: {status: 'error', error: 'Unable to unfollow event.'}
    end
  end

  def index
    filtered_query = Event.all.map { |x| x.decorate.to_hash(current_username, request_options) }
    render json: {status: 'ok', total_count: filtered_query.length, events: filtered_query}
  end

  def show
    render json: {status: 'ok', event: @event.decorate.to_hash(current_username, request_options)}
  end

  def mine
    day = Time.from_param(params[:day])
    events = Event.where(:start_time.gte => day.beginning_of_day).where(:start_time.lt => day.end_of_day).where(favorites: current_username).order_by(:start_time.asc)
    render json: {status: 'ok', events: events.map { |x| x.decorate.to_hash(current_username, request_options) }, today: day.to_ms, prev_day: (day - 1.day).to_ms, next_day: (day + 1.day).to_ms}
  end

  def day
    day = Time.from_param(params[:day])
    events = Event.where(:start_time.gte => day.beginning_of_day).where(:start_time.lt => day.end_of_day).order_by(:start_time.asc)
    render json: {status: 'ok', events: events.map { |x| x.decorate.to_hash(current_username, request_options) }, today: day.to_ms, prev_day: (day - 1.day).to_ms, next_day: (day + 1.day).to_ms}
  end

  private
  def fetch_event
    begin
      @event = Event.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status: 'error', id: params[:id], error: "Event not found."}
    end
  end
end
