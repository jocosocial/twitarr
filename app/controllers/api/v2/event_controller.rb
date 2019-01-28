require 'csv'
class API::V2::EventController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :login_required, :only => [:follow, :unfollow, :mine]
  before_filter :admin_required, :only => [:destroy, :update]
  before_filter :fetch_event, :except => [:index, :csv, :all, :mine]

  def fetch_event
    begin
      @event = Event.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status: 'Not found', id: params[:id], error: "Event by id #{params[:id]} is not found."}
    end
  end

  def update
    @event.title = params[:title] if params.has_key? :title
    @event.description = params[:description] if params.has_key? :description
    @event.location = params[:location] if params.has_key? :location
    if params.has_key? :start_time
      if params[:start_time] =~ /^\d+$/
        @event.start_time = Time.at(params[:start_time].to_i / 1000.0)
      else
        @event.start_time = Time.parse(params[:start_time])
      end
    end
    @event.end_time = Time.parse(params[:end_time]) unless params[:end_time].blank?

    if @event.save
      render json: {events: @event.decorate.to_hash(current_username)}
    else
      render json: {errors: @event.errors.full_messages}
    end
  end

  def destroy
    if @event.destroy
      render json: {status: :ok}
    else
      render json: {status: :error, error: @event.errors}
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
      render json: {status: 'ok'}
    else
      render json: {status: 'error', errors: @event.errors}
    end
  end

  def unfollow
    @event.unfollow current_username
    if @event.save
      render json: {status: 'ok'}
    else
      render json: {status: 'error', errors: @event.errors}
    end
  end

  def index
    sort_by = (params[:sort_by] || 'start_time').to_sym
    order = (params[:order] || 'desc').to_sym
    query = Event.all.order_by([sort_by, order])
    filtered_query = query.map { |x| x.decorate.to_hash current_username }
    result = [status: 'ok', total_count: filtered_query.length, events: filtered_query]
    respond_to do |format|
      format.json { render json: result }
      format.xml { render xml: result }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @event.decorate.to_hash(current_username) }
      format.xml { render xml: @event.decorate.to_hash(current_username) }
    end
  end

  def mine
    day = Date.parse params[:day]
    events = Event.where(:start_time.gte => day.to_time + 4.hours).where(:start_time.lt => day.to_time + 28.hours).where(favorites: current_username).order_by(:start_time.asc)
    render json: {events: events.map { |x| x.decorate.to_meta_hash(current_username) }, today: day.to_s, prev_day: (day - 1).to_s, next_day: (day + 1).to_s}
  end

  def all
    day = Date.parse params[:day]
    events = Event.where(:start_time.gte => day.to_time + 4.hours).where(:start_time.lt => day.to_time + 28.hours).order_by(:start_time.asc)
    render json: {events: events.map { |x| x.decorate.to_meta_hash(current_username) }, today: day.to_s, prev_day: (day - 1).to_s, next_day: (day + 1).to_s}
  end
end
