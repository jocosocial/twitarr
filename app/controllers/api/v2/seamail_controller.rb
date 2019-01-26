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
      render status: :not_found, json: {status:'error', error: "Seamail not found"} and return
    end
  end

  def index
    extra_query = {}
    counting_unread = false
    if params[:unread] && params[:unread].to_bool
      extra_query[:unread] = true
      counting_unread = true
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

    if @include_messages
      output = "seamail_threads"
      options = request_options
      if @exclude_read_messages
        options[:exclude_read_messages] = true
      end
      mails = mails.map { |x| x.decorate.to_hash(options, current_username, counting_unread) }
    else
      output = "seamail_meta"
      mails = mails.map { |x| x.decorate.to_meta_hash(current_username, counting_unread) }
    end

    render json: {status: 'ok', output => mails, last_checked: Time.now.to_ms}
  end

  def threads
    @include_messages = true
    if params[:exclude_read_messages]
      @exclude_read_messages = true
    end
    index
  end

  def show
    mails = @seamail.decorate.to_hash(request_options, current_username)
    @seamail.mark_as_read current_username unless params[:skip_mark_read]
    render json: {status: 'ok', seamail: mails}
  end

  def create
    seamail = Seamail.create_new_seamail current_username, params[:users], params[:subject], params[:text]
    if seamail.valid?
      render json: {status: 'ok', seamail: seamail.decorate.to_hash(request_options, current_username)}
    else
      render status: :bad_request, json: {status: 'error', errors: seamail.errors.full_messages}
    end
  end

  def new_message
    message = @seamail.add_message current_username, params[:text]
    if message.valid?
      render json: {status: 'ok', seamail_message: message.decorate.to_hash(request_options, current_username)}
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
    render json: {status: 'ok', seamail_meta: @seamail.decorate.to_meta_hash(current_username)}
  end

end
