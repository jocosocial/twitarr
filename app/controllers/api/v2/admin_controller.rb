class API::V2::AdminController < ApplicationController
	skip_before_action :verify_authenticity_token
	
	before_filter :has_access
	
	def has_access
		head :unauthorized unless (logged_in? || valid_key?(params[:key])) && is_admin?
	end
	
	def users
		render json: {status: 'ok', list: User.all.asc(:username).map { |x| x.decorate.admin_hash }}
	end
	
	def user
		search_text = params[:username].strip.downcase.gsub(/[^\w&\s-]/, '')
		user_query = User.search(params)
		render json: {status: 'ok', search_text: search_text, users: user_query.map{|x| x.decorate.admin_hash }}
	end
	
	def update_user
		user = User.get(params[:username])
		
		render json: {status: 'User does not exist.'} and return unless user
		
		user.is_admin = params[:is_admin] == 'true'
		
		# don't let the user turn off his own admin status
		user.is_admin = true if user.username == current_username
		
		user.status = params[:status]
		user.email = params[:email]
		user.display_name = params[:display_name]
		if user.invalid?
			render json: {status: 'invalid', errors: user.errors.messages} and return
		end
		user.save
		render json: {status: 'ok'}
	end

	def activate
		user = User.get(params[:username])
		
		render json: {status: 'User does not exist.'} and return unless user
		
		user.status = User::ACTIVE_STATUS
		user.save
		render json: {status: 'ok'}
	end

	def reset_password
		user = User.get(params[:username])
		
		render json: {status: 'User does not exist.'} and return unless user
		
		user.password = BCrypt::Password.create User::RESET_PASSWORD
		user.save
		render json: {status: 'ok'}
	end
	
	def announcements
		render json: {status: 'ok', list: Announcement.all.desc(:timestamp).map { |x| x.decorate.to_admin_hash }}
	end
	
	def new_announcement
		time = Time.now
		valid_until = time + params[:hours].to_i.hours
		
		render json: {status: 'Announcement hours must be greater than zero.'} and return unless valid_until > time
		
		Announcement.create(author: current_username, text: params[:text], timestamp: time, valid_until: valid_until)
		render json: {status: 'ok'}
	end
	
	def upload_schedule
		upload = params[:schedule].tempfile.read
		temp = upload.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
		Icalendar.parse(temp).first.events.map { |x| Event.create_from_ics x }
		render json: {status: 'ok'}
	end
end