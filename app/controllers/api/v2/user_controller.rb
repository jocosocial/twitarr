class API::V2::UserController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :login_required, :only => [:new_seamail, :whoami, :star, :starred, :personal_comment, :update_profile, :reset_photo, :update_photo, :reset_mentions, :mentions, :likes]

  def new
    if logged_in?
      render status: :bad_request, json: {status: "error", errors: { general: ["Already logged in - log out before creating a new account."]}}
      return
    end
    new_username = params[:new_username].downcase unless params[:new_username].blank?
    display_name = params[:display_name] 
    display_name = params[:new_username] if params[:display_name].blank?
    user = User.new username: new_username, display_name: display_name, password: params[:new_password],
                     is_admin: false, status: User::ACTIVE_STATUS, email: params[:email],
                     security_question: params[:security_question], security_answer: params[:security_answer], registration_code: params[:registration_code]
    
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
      render status: :unauthorized, json: { :status => 'incorrect username or password' } and return
    else
      @user = login_result[:user]
      login_user @user
      render json: { :status => 'ok', :username => @user.username, :key => build_key(@user.username) }
    end
  end

  def security_question
    params[:username] ||= ''
    params[:email] ||= 'invalid'
    user = User.where(username: params[:username].downcase).first
    if user.nil? or user.email != params[:email].downcase
      render status: :bad_request, json: { :status => 'error', errors: {username: ['Username and email combination not found.']}} and return
    else
      render json: {:status => 'ok', security_question: user.security_question }
    end
  end

  def reset_password
    params[:username] ||= ''
    params[:email] ||= 'invalid'
    params[:security_answer] ||= ''
    user = User.where(username: params[:username].downcase).first
    if user.nil? or user.email != params[:email].downcase
      render status: :bad_request, json: { :status => 'error', errors: {username: ['Username and email combination not found.']}} and return
    end
    if params[:security_answer].downcase.strip != user.security_answer.downcase
      sleep 10.seconds.to_i
      render status: :bad_request, json: { :status => 'error', errors: {security_answer: ['Security answer did not match.']}} and return
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

  def autocomplete
    search = params[:username].downcase
    render json: {
      names: User.or(
        { username: /^#{search}/ },
        { display_name: /^#{search}/i },
      ).map { |x| { username: x.username, display_name: x.display_name } }
    }
  end

  def whoami
    render json: {
      :status => 'ok', 
      user: UserDecorator.decorate(current_user).self_hash,
      need_password_change: current_user.correct_password(User::RESET_PASSWORD)
    }
  end

  def show
    user = User.get params[:username]
    if user.nil?
      render json: { status: "User #{params[:username]} does not exist."}
      return
    end
    hash = user.decorate.public_hash.merge(
      {
          recent_tweets: StreamPost.where(author: user.username).desc(:timestamp).limit(10).map { |x| x.decorate.to_hash(current_username, request_options) }
      })
    hash[:starred] = current_user.starred_users.include?(user.username) if logged_in? 
    hash[:comment] = current_user.personal_comments[user.username] if logged_in?
    render json: { status: 'ok', user: hash }
  end

  def star
    show_username = User.format_username params[:username]
    user = User.get show_username
    render json: {status: 'User does not exist.'} and return unless User.exist?(params[:username])
    starred = current_user.starred_users.include? show_username
    if starred
      current_user.starred_users.delete show_username
    else
      current_user.starred_users << show_username
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
    render json: {status: 'User does not exist.'} and return unless User.exist?(params[:username])

    show_username = User.format_username params[:username]
    current_user.personal_comments[show_username] = params[:comment]
    current_user.save
    render json: {status: 'ok'}
  end

  def update_profile
    message = 'Profile Updated.'

    password_change = false
    if params[:new_password] && params[:current_password]
      unless current_user.correct_password(params[:current_password])
        render status: :unauthorized, json: { status: 'Current password is incorrect.' }
        return
      end
      current_user.password = params[:new_password]
      password_change = true
    end

    current_user.current_location = params[:current_location] if params.has_key? :current_location
    current_user.display_name = params[:display_name] if params.has_key? :display_name
    current_user.email = params[:email] if params.has_key? :email
    current_user.email_public = params[:email_public?] if params.has_key? :email_public?
    current_user.home_location = params[:home_location] if params.has_key? :home_location
    current_user.real_name = params[:real_name] if params.has_key? :real_name
    current_user.room_number = params[:room_number] if params.has_key? :room_number
    if current_user.valid?
      if password_change
        current_user.set_password params[:new_password]
        message += ' Password changed.'
      end
      current_user.save
      render json: { status: message, user: UserDecorator.decorate(current_user).self_hash } and return
    else
      render json: { status: 'Error', errors: current_user.errors.full_messages } and return
    end
  end

  def get_photo
    user = User.get params[:username]
    response.headers['Etag'] = user.photo_hash
    expires_in 1.second
    if user
      if params[:full]
        send_file user.full_profile_picture_path, disposition: 'inline'
      else
        send_file user.profile_picture_path, disposition: 'inline'
      end

    else
      Rails.logger.error "get_photo: User #{params[:username]} was not found.  Using 404 image."
      redirect_to '/img/404_file_not_found_sign_by_zutheskunk.png'
    end
  end

  def reset_photo
    render json: current_user.reset_photo
  end

  def update_photo
    render json: {status: 'Must provide a photo to upload.'} and return unless params[:file]
    render json: current_user.update_photo(params[:file])
  end

  def reset_mentions
    current_user.reset_mentions
    render json: { status: 'OK', user: UserDecorator.decorate(current_user).self_hash }
  end

  def mentions
    render json: { mentions: current_user.unnoticed_mentions }
  end

  def likes
    limit = params[:limit] || 20
    skip = params[:skip] || 0
    query = current_user.liked_posts.limit(limit).skip(skip)
    count = query.length
    result = [status: 'ok', user: current_user.username, total_count: count, next: (skip + limit), items: query.length, likes: query]
    respond_to do |format|
      format.json { render json: result }
      format.xml { render xml: result }
    end
  end

  def logout
    logout_user
    render json: {status: 'ok'}
  end
end
