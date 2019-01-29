class ApplicationController < ActionController::Base
  #protect_from_forgery with: :exception
  def index
  end
  
  def logged_in?
    !current_username.nil? && !current_user.nil?
  end

  def current_username
    return @current_user.username if @current_user
    return session[:username] if session[:username]
    return get_username(params[:key]) if valid_key?(params[:key])
    return nil
  end

  def current_user
    @current_user ||= User.get current_username
  end

  def login_user(user)
    session[:username] = user.username
    session[:is_admin] = user.is_admin
    puts "Successful login for user: #{current_username}"
  end

  def logout_user
    session.delete :username
    session.delete :is_admin
  end

  def is_admin?
    (current_user&.is_admin) || session[:is_admin]
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

  def read_only_mode
    render json: { status: 'Twit-arr is in storage (read-only) mode.' }
  end

  def build_key(name, days_back = 0)
    digest = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest::SHA1.new,
        Twitarr::Application.config.secret_key_base,
        "#{name}#{Time.now.year}#{Time.now.yday - days_back}"
    )
    "#{name}:#{digest}"
  end

  def request_options
    ret = {}
    ret[:app] = params[:app] if !params.nil? and params.has_key?(:app)
    ret
  end

  private

  def get_username(key)
    return nil if key.nil?
    key = URI.unescape(key)
    key.split(':').first
  end

  def login_with_key(key)
    @user = User.get get_username(key)
  end

  def valid_key?(key)
    return false if key.nil?
    key = URI.unescape(key)
    return false unless key.include? ':'
    username = get_username key
    CHECK_DAYS_BACK.times do |x|
      if build_key(username, x) == key
        login_with_key key
        return true
      end
    end
    false
  end

  CHECK_DAYS_BACK = 10
  
end
