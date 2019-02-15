class API::V2::SeamailController < ApplicationController
  # noinspection RailsParamDefResolve
  skip_before_action :verify_authenticity_token

  before_action :login_required
  before_action :not_muted, :only => [:create, :new_message, :recipients]
  before_action :fetch_seamail, :only => [:show, :new_message, :recipients]
  before_action :fetch_as_user

  def fetch_seamail
    begin
      @seamail = Seamail.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status:'error', error: "Seamail not found"} and return
    end
    unless @seamail.usernames.include?(current_username) || (is_moderator? && @seamail.usernames.include?('moderator'))
      render status: :not_found, json: {status:'error', error: "Seamail not found"} and return
    end
  end

  def fetch_as_user
    if(post_as_user(params) != current_username)
      puts post_as_user(params)
      @as_user = User.get 'moderator'
    else
      @as_user = current_user
    end
  end

  def index
    extra_query = {}
    counting_unread = false
    begin
      if params[:unread] && params[:unread].to_bool
        extra_query[:unread] = true
        counting_unread = true
      end
    rescue ArgumentError => e
      render status: :bad_request, json: {status: 'error', error: e.message} and return
    end
    if params[:after]
      val = Time.from_param(params[:after])
      if val
        extra_query[:after] = val
      end
    end
    
    puts "Current user: #{@as_user.username}"
    mails = @as_user.seamails extra_query

    if @include_messages
      output = "seamail_threads"
      options = request_options
      if @exclude_read_messages
        options[:exclude_read_messages] = true
      end
      mails = mails.map { |x| x.decorate.to_hash(options, @as_user.username, counting_unread) }
    else
      output = "seamail_meta"
      mails = mails.map { |x| x.decorate.to_meta_hash(@as_user.username, counting_unread) }
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
    mails = @seamail.decorate.to_hash(request_options, @as_user.username)
    @seamail.mark_as_read @as_user.username unless params[:skip_mark_read]
    render json: {status: 'ok', seamail: mails}
  end

  def create
    puts "Posting as user: #{@as_user.username}"
    seamail = Seamail.create_new_seamail @as_user.username, params[:users], params[:subject], params[:text], current_username
    if seamail.valid?
      render json: {status: 'ok', seamail: seamail.decorate.to_hash(request_options, @as_user.username)}
    else
      render status: :bad_request, json: {status: 'error', errors: seamail.errors.full_messages}
    end
  end

  def new_message
    message = @seamail.add_message @as_user.username, params[:text], current_username
    if message.valid?
      render json: {status: 'ok', seamail_message: message.decorate.to_hash(request_options, @as_user.username)}
    else
      render status: :bad_request, json: {status: 'error', errors: message.errors.full_messages}
    end
  end

  def recipients
    # this ensures that the logged in user is also specified
    usernames = params[:users]
    usernames ||= []
    usernames << @as_user.username unless usernames.include? @as_user.username
    usernames = usernames.map(&:downcase).uniq
    @seamail.usernames = usernames
    if @seamail.valid?
      @seamail.save!
    else
      render status: :bad_request, json: {status: 'error', errors: @seamail.errors.full_messages} and return
    end
    render json: {status: 'ok', seamail_meta: @seamail.decorate.to_meta_hash(@as_user.username)}
  end

end
