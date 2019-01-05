class API::V2::SeamailController < ApplicationController
  # noinspection RailsParamDefResolve
  skip_before_action :verify_authenticity_token

  before_filter :login_required
  before_filter :fetch_seamail, :only => [:show, :new_message, :recipients]

  def fetch_seamail
    begin
      @seamail = Seamail.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status:'error', error: "Seamail not found"} and return
    end
    unless @seamail.usernames.include? current_username
      render status: :forbidden, json: {status: 'error', error: 'User must be part of the seamail to access a seamail'}
    end
  end

  def index
    extra_query = {}
    if params[:unread] && params[:unread].to_bool
      extra_query[:unread] = true
    end
    if params[:after]
      val = nil
      if params[:after] =~ /^\d+$/
        val = Time.at(params[:after].to_i / 1000.0)
      else
        val = DateTime.parse params[:after]
      end
      if val
        extra_query[:after] = val
      end
    end
    mails = current_user.seamails extra_query
    render json: {status: 'ok', seamail_meta: mails.map { |x| x.decorate.to_meta_hash.merge!({is_unread: x.messages.any? { |message| message.read_users.exclude?(current_username) }}) },
        last_checked: ((Time.now.to_f * 1000).to_i + 1)}
  end

  def show
    mails = @seamail.decorate.to_hash(request_options).merge!({is_unread: @seamail.messages.any? { |message| message.read_users.exclude?(current_username) }})
    @seamail.mark_as_read current_username
    render json: {status: 'ok', seamail: mails}
  end

  def create
    seamail = Seamail.create_new_seamail current_username, params[:users], params[:subject], params[:text]
    if seamail.valid?
      render json: {status: 'ok', seamail_meta: seamail.decorate.to_meta_hash.merge!({is_unread: seamail.messages.any? { |message| message.read_users.exclude?(current_username) }})}
    else
      render status: :bad_request, json: {status: 'error', errors: seamail.errors.full_messages}
    end
  end

  def new_message
    message = @seamail.add_message current_username, params[:text]
    if message.valid?
      render json: {status: 'ok', seamail_message: message.decorate.to_hash(request_options).merge!({is_unread: @seamail.messages.any? { |message| message.read_users.exclude?(current_username) }})}
    else
      render status: :bad_request, json: {status: 'error', errors: message.errors.full_messages}
    end
  end

  def recipients
    # this ensures that the logged in user is also specified
    usernames = params[:users]
    usernames ||= []
    usernames << current_username unless usernames.include? current_username
    usernames = usernames.map(&:downcase).uniq
    @seamail.usernames = usernames
    if @seamail.valid?
      @seamail.save!
    else
      render status: :bad_request, json: {status: 'error', errors: @seamail.errors.full_messages} and return
    end
    render json: {status: 'ok', seamail_meta: @seamail.decorate.to_meta_hash}
  end

end
