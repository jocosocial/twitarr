class API::V2::UserController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :login_required,  :only => [:rc_update_profile]

  def login_required
    head :unauthorized unless logged_in? || valid_key?(params[:key])
  end

  def new
    if logged_in?
      render_json errors: ["already logged in - log out before creating a new account"]
      return
    end
    new_username = params[:new_username].downcase unless params[:new_username].blank?
    display_name = params[:display_name] 
    display_name = params[:new_username] if params[:display_name].blank?
    user = User.new username: new_username, display_name: display_name, password: params[:new_password],
                     is_admin: false, status: User::ACTIVE_STATUS, email: params[:email],
                     security_question: params[:security_question], security_answer: params[:security_answer], registration_code: params[:registration_code]
    
    if !user.valid?
      render_json errors: user.errors.full_messages
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
      render json: { :status => 'incorrect username or password' }, status: 401 and return
    else
      @user = login_result[:user]
      login_user @user
      render json: { :status => 'ok', :key => build_key(@user.username) }
    end
  end

  def new_seamail
    return unless logged_in!
    render_json :status => 'ok', email_count: current_user.seamail_unread_count
  end

  def autocomplete
    search = params[:username].downcase
    render_json names: User.or(
      { username: /^#{search}/ },
      { display_name: /^#{search}/i },
    ).map { |x| { username: x.username, display_name: x.display_name } }
  end

  def whoami
    return unless logged_in!
    render_json :status => 'ok', user: UserDecorator.decorate(current_user).self_hash
  end

  def show
    user = User.get params[:username]
    if user.nil?
      render status: :ok, json: { status: "User #{params[:username]} does not exist."}
      return
    end
    hash = user.decorate.public_hash.merge(
      {
          recent_tweets: StreamPost.where(author: user.username).desc(:timestamp).limit(10).map { |x| x.decorate.to_hash(current_username) }
      })
    hash[:starred] = current_user.starred_users.include?(user.username) if logged_in? 
    render status: :ok, json: { status: 'ok', user: hash }
  end

  def vcard
    # I apologize for this mess. It's not clean but it works.
    user = User.get params[:username]
    render body: 'User has vcard disabled', content_type: 'text/plain' and return unless user.is_vcard_public?
    formatted_name = (user.real_name if user.real_name?) || (user.display_name if user.display_name?) || user.username
    photo = Base64.encode64(open(user.profile_picture_path) { |io| io.read }).tr("\n", "")

    card_string = "BEGIN:VCARD\n"
    card_string << "VERSION:4.0\n"
    card_string << "FN:#{formatted_name}\n"
    card_string << "PHOTO;JPEG;ENCODING=BASE64:#{photo}\n"
    card_string << "EMAIL:#{user.email}\n" if user.email? and user.is_email_public?
    card_string << "NOTE:Room Number: #{user.room_number}\n" if user.room_number?
    card_string << "SOURCE:#{request.original_url}\n"
    # We should probably add more fields for users to fill out for this stuff :)
    card_string << "END:VCARD"
    headers['Content-Disposition'] = "inline; filename=\"#{user.username}.vcf\""

    render body: card_string, content_type: 'text/vcard', layout: false 
  end

  def star
    return unless logged_in!
    show_username = User.format_username params[:username]
    user = User.get show_username
    render_json status: 'User does not exist.' and return unless User.exist?(params[:username])
    starred = current_user.starred_users.include? show_username
    if starred
      current_user.starred_users.delete show_username
    else
      current_user.starred_users << show_username
    end
    current_user.save
    render_json status: 'ok', starred: !starred
  end

  def starred
    return unless logged_in!
    users = User.where(:username.in => current_user.starred_users)
    hash = users.map do |u|
      username = User.format_username u.username
      uu = u.decorate.gui_hash
      uu.merge!({comment: current_user.personal_comments[username]})
      uu
    end
    render_json status: 'ok', users: hash
  end

  def update_profile
    return unless logged_in!

    message = 'Profile Updated.'

    if params[:new_password] && params[:current_password]
      unless current_user.correct_password(params[:current_password])
        render status: :unauthorized, json: { status: 'Current password is incorrect.' }
        return
      end
      current_user.set_password params[:new_password]
      message += ' Password changed.'
    end

    current_user.current_location = params[:current_location] if params.has_key? :current_location
    current_user.display_name = params[:display_name] if params.has_key? :display_name
    current_user.email = params[:email] if params.has_key? :email
    current_user.email_public = params[:email_public?] if params.has_key? :email_public?
    current_user.home_location = params[:home_location] if params.has_key? :home_location
    current_user.real_name = params[:real_name] if params.has_key? :real_name
    current_user.room_number = params[:room_number] if params.has_key? :room_number
    current_user.vcard_public = params[:vcard_public?] if params.has_key? :vcard_public?
    if current_user.valid?
      current_user.save
      render status: :ok, json: { status: message, user: UserDecorator.decorate(current_user).self_hash } and return
    else
      render status: :ok, json: { status: 'Error', errors: current_user.errors.full_messages } and return
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
    return unless logged_in!
    render_json current_user.reset_photo
  end

  def update_photo
    return unless logged_in!
    render_json(status: 'Must provide a photo to upload.') and return unless params[:file]
    render_json current_user.update_photo params[:file]
  end

  def reset_mentions
    return unless logged_in!
    current_user.reset_mentions
    render status: :ok, json: { status: 'OK', user: UserDecorator.decorate(current_user).self_hash }
  end

  def mentions
    return unless logged_in!
    render status: :ok, json: { mentions: current_user.unnoticed_mentions }
  end

  def likes
    return unless logged_in!
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
    render_json status: 'ok'
  end
  
  def rc_users
    return unless valid_key?(params[:key])
    start_loc = params[:since]
    limit = params[:limit] || 0
    users = User.where(:updated_at.gte => start_loc).only(:id, :updated_at, :username, :display_name, :real_name, :email, :home_location, :last_photo_updated, :room_number, :is_email_public, :is_vcard_public).limit(limit).order_by(username: :asc)
    render json: users 
  end
  
  def rc_update_profile
    return unless logged_in!
    current_user.display_name = params[:display_name] if params.has_key? :display_name
    current_user.email = params[:email] if params.has_key? :email
    current_user.email_public = params[:email_public] if params.has_key? :email_public
    current_user.home_location = params[:home_location] if params.has_key? :home_location
    current_user.real_name = params[:real_name] if params.has_key? :real_name
    current_user.room_number = params[:room_number] if params.has_key? :room_number
    current_user.vcard_public = params[:vcard_public] if params.has_key? :vcard_public
    if current_user.valid?
      current_user.save
      render json: { status: 'Updated' }
    else
      render json: { status: 'Error', errors: current_user.errors.full_messages }
    end
  end
		
end
