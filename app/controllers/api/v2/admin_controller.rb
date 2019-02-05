class API::V2::AdminController < ApplicationController
	skip_before_action :verify_authenticity_token
	
	before_filter :admin_required
	before_filter :fetch_user, :only => [:update_user, :activate, :reset_password]
	
	def users
		render json: {status: 'ok', list: User.all.asc(:username).map { |x| x.decorate.admin_hash }}
	end
	
	def user
		search_text = params[:query].strip.downcase.gsub(/[^\w&\s-]/, '')
		user_query = User.search(params)
		render json: {status: 'ok', search_text: search_text, users: user_query.map{|x| x.decorate.admin_hash }}
	end
	
	def update_user
		@user.is_admin = params[:is_admin] == 'true'
		
		# don't let the user turn off his own admin status
		@user.is_admin = true if @user.username == current_username
		
		@user.status = params[:status]
		@user.email = params[:email]
		@user.display_name = params[:display_name]
		
		render status: :bad_request, json: {status: 'error', errors: @user.errors.messages} and return unless @user.valid?

		@user.save
		render json: {status: 'ok', user: @user.decorate.admin_hash}
	end

	def activate
		@user.status = User::ACTIVE_STATUS
		@user.save
		render json: {status: 'ok', user: @user.decorate.admin_hash}
	end

	def reset_password
		@user.password = BCrypt::Password.create User::RESET_PASSWORD
		@user.save
		render json: {status: 'ok'}
	end
	
	def announcements
		render json: {status: 'ok', list: Announcement.all.desc(:timestamp).map { |x| x.decorate.to_admin_hash }}
	end
	
	def new_announcement
		time = Time.now
		errors = []

		errors.push('Text is required.') if params[:text].nil? || params[:text].empty?

		begin
			valid_until = Time.from_param(params[:valid_until])
		rescue
			errors.push('Unable to parse valid until.')
		else
			errors.push('Valid until must be in the future.') unless valid_until > time
		end		

		render status: :bad_request, json: {status: 'error', errors: errors} and return unless errors.length == 0
		
		Announcement.create(author: current_username, text: params[:text], timestamp: time, valid_until: valid_until)
		render json: {status: 'ok'}
	end
	
	def upload_schedule
		begin
			upload = params[:schedule].tempfile.read
			temp = upload.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
			Icalendar::Calendar.parse(temp).first.events.map { |x| Event.create_from_ics x }
		rescue StandardError => e
			render status: :bad_request, json: {status: 'error', error: "Unable to parse schedule: #{e.message}"} and return
		end
		render json: {status: 'ok'}
	end

	private
	def fetch_user
    @user = User.get params[:username]
    render status: :not_found, json: {status: 'error', error: 'User not found.'} and return unless @user
  end
end