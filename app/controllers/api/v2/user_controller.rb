class API::V2::UserController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :login_required, :only => [:new_seamail, :whoami, :star, :starred, :personal_comment, :update_profile, :change_password, :reset_photo, :update_photo, :reset_mentions, :mentions]
  before_filter :fetch_user, :only => [:show, :star, :personal_comment, :get_photo]

  def fetch_user
    @user = User.get params[:username]
    render status: :not_found, json: {status: 'error', error: 'User not found.'} and return unless @user
  end

  def new
    if logged_in?
      render status: :bad_request, json: {status: "error", errors: { general: ["Already logged in - log out before creating a new account."]}}
      return
    end
    new_username = params[:new_username].downcase unless params[:new_username].blank?
    display_name = params[:display_name] 
    display_name = params[:new_username] if params[:display_name].blank?
    user = User.new username: new_username, display_name: display_name, password: params[:new_password],
                     is_admin: false, status: User::ACTIVE_STATUS, registration_code: params[:registration_code]
    
    if !user.valid?
      render status: :bad_request, json: {status: "error", errors: user.errors.messages}
      return
    else
      user.set_password params[:new_password]
      user.update_last_login.save
      login_user user
      render json: { :status => 'ok', :key => build_key(user.username), user: UserDecorator.decorate(user).self_hash }
    end
  end

  def auth
    login_result = validate_login params[:username], params[:password]
    if login_result.has_key? :error
      render status: :unauthorized, json: { status: 'error', error: login_result[:error] } and return
    else
      @user = login_result[:user]
      login_user @user
      render json: { :status => 'ok', :username => @user.username, :key => build_key(@user.username) }
    end
  end

  def reset_password
    params[:username] ||= ''
    params[:registration_code] ||= ''
    user = User.where(username: User.format_username(params[:username])).first
    if user.nil? or user.registration_code != params[:registration_code].downcase
      sleep 10.seconds.to_i
      render status: :bad_request, json: { :status => 'error', errors: {username: ['Username and registration code combination not found.']}} and return
    end

    # Check validity of new password
    new_pass = params[:new_password]
    user.password = new_pass
    render status: :bad_request, json: { :status => 'error', errors: {password: ['Your password must be at least six characters long.']}} and return unless user.valid?

    user.set_password params[:new_password]
    user.save!
    render json: { :status => 'ok', message: 'Your password has been changed!' }
  end

  def new_seamail
    render json: {:status => 'ok', email_count: current_user.seamail_unread_count}
  end

  def auto_complete
    params[:query] ||= ''
    query = params[:query].downcase
    query = query[1..-1] if query[0] == '@'
    unless query && query.size >= User::MIN_AUTO_COMPLETE_LEN
      render status: :bad_request, json: {status: 'error', error: "Minimum length is #{User::MIN_AUTO_COMPLETE_LEN}"}
      return
    end
    render json: {status: "ok", users: User.auto_complete(query).map { |x| x.decorate.gui_hash }}
  end

  def whoami
    render json: {
      :status => 'ok', 
      user: UserDecorator.decorate(current_user).self_hash,
      need_password_change: current_user.correct_password(User::RESET_PASSWORD)
    }
  end

  def show
    hash = @user.decorate.public_hash.merge(
      {
          recent_tweets: StreamPost.where(author: @user.username).desc(:id).limit(10).map { |x| x.decorate.to_hash(current_username, request_options) }
      })
    hash[:starred] = current_user.starred_users.include?(@user.username) if logged_in? 
    hash[:comment] = current_user.personal_comments[@user.username] if logged_in?
    render json: { status: 'ok', user: hash }
  end

  def star
    starred = current_user.starred_users.include? @user.username
    if starred
      current_user.starred_users.delete @user.username
    else
      current_user.starred_users << @user.username
    end
    current_user.save
    render json: {status: 'ok', starred: !starred}
  end

  def starred
    users = User.where(:username.in => current_user.starred_users)
    hash = users.map do |u|
      username = User.format_username u.username
      uu = u.decorate.gui_hash
      uu.merge!({comment: current_user.personal_comments[username]})
      uu
    end
    render json: {status: 'ok', users: hash}
  end

  def personal_comment
    current_user.personal_comments[@user.username] = params[:comment]
    current_user.save
    render json: {status: 'ok'}
  end

  def update_profile
    current_user.current_location = params[:current_location] if params.has_key? :current_location
    # current_user.display_name = params[:display_name] if params.has_key? :display_name
    current_user.email = params[:email] if params.has_key? :email
    current_user.home_location = params[:home_location] if params.has_key? :home_location
    current_user.real_name = params[:real_name] if params.has_key? :real_name
    current_user.pronouns = params[:pronouns] if params.has_key? :pronouns
    current_user.room_number = params[:room_number] if params.has_key? :room_number

    render json: { status: 'error', errors: current_user.errors } and return unless current_user.valid?

    current_user.save
    render json: { status: 'ok', user: UserDecorator.decorate(current_user).self_hash } and return
  end

  def change_password
    errors = {}

    unless params[:current_password] && current_user.correct_password(params[:current_password])
      errors[:current_password] = ["Current password is incorrect."]
    end

    current_user.password = params[:new_password]

    unless current_user.valid?
      errors[:new_password] = ["New password must be at least six characters long."]
    end

    render status: :bad_request, json: {status: 'error', errors: errors} and return unless errors.length == 0

    current_user.set_password params[:new_password]
    current_user.save
    render json: { status: 'ok' } and return
  end

  def get_photo
    response.headers['Etag'] = @user.photo_hash
    expires_in 1.second
    
    if params[:full]
      send_file @user.full_profile_picture_path, disposition: 'inline'
    else
      send_file @user.profile_picture_path, disposition: 'inline'
    end
  end

  def reset_photo
    render json: current_user.reset_photo
  end

  def update_photo
    render status: :bad_request, json: {status: 'error', error: 'Must provide photo to upload.'} and return unless params[:file]
    results = current_user.update_photo(params[:file])
    if results.fetch(:status) == 'error'
      render status: :bad_request, json: results
    else
      render json: results
    end
  end

  def reset_mentions
    current_user.reset_mentions
    render json: { status: 'ok', user: UserDecorator.decorate(current_user).self_hash }
  end

  def mentions
    render json: { mentions: current_user.unnoticed_mentions }
  end

  def logout
    logout_user
    render json: {status: 'ok'}
  end

end
