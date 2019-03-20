class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  def index
  end
  
  def logged_in?
    !current_username.nil? && !current_user.nil? && current_user.role != User::Role::BANNED
  end

  def current_username
    return @current_user.username if @current_user
    return session[:username] if session[:username]
    return parse_key(params[:key]).first if valid_key?(params[:key])
    return nil
  end

  def current_user
    @current_user ||= User.get current_username
  end

  def login_user(user)
    session[:username] = user.username
    session[:role] = user.role
    puts "Successful login for user: #{current_username}"
  end

  def logout_user
    session.delete :username
    session.delete :role
  end

  def is_admin?
    (current_user&.role == User::Role::ADMIN) || (session[:role] == User::Role::ADMIN)
  end

  def is_tho?
    (!current_user.nil? && current_user.role >= User::Role::THO) || (!session[:role].nil? && session[:role] >= User::Role::THO)
  end

  def is_moderator?
    (!current_user.nil? && current_user.role >= User::Role::MODERATOR) || (!session[:role].nil? && session[:role] >= User::Role::MODERATOR)
  end

  def is_muted?
    (current_user&.role == User::Role::MUTED) || (session[:role] == User::Role::MUTED)
  end

  def validate_login(username, password)
    user = User.get username
    result = {user: user}
    if user.nil?
      result[:error] = 'Invalid username or password.'
    elsif user.empty_password? # We need to check this condition before comparing passwords
      result[:error] = 'User account has been disabled.'
    elsif !user.correct_password(password)
      result[:error] = 'Invalid username or password.'
    elsif user.status != User::ACTIVE_STATUS # If a user's password is set, we only want to report they're locked if they have the right password
      result[:error] = 'User account has been disabled.'
    elsif user.role == User::Role::BANNED
      result[:error] = "User account has been banned. Reason: #{user.ban_reason}"
    else
      user.update_last_login.save
    end
    result
  end

  def login_required
    head :unauthorized unless logged_in?
  end

  def admin_required
		head :unauthorized unless logged_in? && is_admin?
  end
  
  def tho_required
		head :unauthorized unless logged_in? && is_tho?
  end
  
  def moderator_required
		head :unauthorized unless logged_in? && is_moderator?
  end
  
  def not_muted
    render status: :forbidden, json: { status: 'error', error: 'You have been muted. Check your seamail or see the help page for more information.' } unless logged_in? && !is_muted?
  end

  def read_only_mode
    render json: { status: 'Twit-arr is in storage (read-only) mode.' }
  end

  def build_key(name, hashed_password, expiration = 0)
    expiration = (Time.now + KEY_EXPIRATION_DAYS.days).to_ms if expiration == 0

    digest = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest::SHA1.new,
        Twitarr::Application.config.secret_key_base,
        "#{name}#{hashed_password}#{expiration}"
    )
    "#{name}:#{expiration}:#{digest}"
  end

  def request_options
    ret = {}
    ret[:app] = params[:app] if !params.nil? and params.has_key?(:app)
    ret
  end

  def post_as_user(params)
    if params.has_key?(:as_mod) && params[:as_mod].to_bool && is_moderator?
      return 'moderator'
    elsif params.has_key?(:as_admin) && params[:as_admin].to_bool && is_admin?
      return 'twitarrteam'
    end
    return current_username
  end

  def forums_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'Forums are currently disabled.'} unless Section.enabled?(:forums)
    end
  end

  def stream_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'Stream is currently disabled.'} unless Section.enabled?(:stream)
    end
  end

  def seamail_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'Seamail is currently disabled.'} unless Section.enabled?(:seamail)
    end
  end

  def events_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'Calendar is currently disabled.'} unless Section.enabled?(:calendar)
    end
  end

  def search_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'Search is currently disabled.'} unless Section.enabled?(:search)
    end
  end

  def registration_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'Registration is currently disabled.'} unless Section.enabled?(:registration)
    end
  end

  def profile_enabled
    if !is_moderator?
      render status: :service_unavailable, json: {status: 'error', error: 'User profiles are currently disabled.'} unless Section.enabled?(:user_profile)
    end
  end
  
  private

  def parse_key(key)
    return nil if key.nil?
    key = URI.unescape(key)
    key = key.split(':')
    return nil if key.length != 3
    key
  end

  def valid_key?(key)
    return false if key.nil? # No key was passed, abort

    key = URI.unescape(key)
    username, expiration, digest = parse_key(key)
    return false if username.nil? or expiration.nil? or digest.nil?
    
    begin
      return false if Time.from_param(expiration) < Time.now # Key expiration is in the past, abort
    rescue
      return false # Couldn't parse the expiration, abort
    end

    user = User.get(username)
    return false if user.nil? or (user.role == User::Role::BANNED) # User not found or user is banned, abort

    if build_key(user.username, user.password, expiration) == key
      @current_user = user # Key is valid for this user, log them in
      return true
    end
    false # Key is too old or did not match the username/hashed password check
  end

  KEY_EXPIRATION_DAYS = 10
  
end
