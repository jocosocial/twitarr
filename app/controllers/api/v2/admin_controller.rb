class API::V2::AdminController < ApplicationController
	skip_before_action :verify_authenticity_token
	
	before_action :moderator_required, :only => [:users, :user, :profile, :update_user, :reset_photo]
	before_action :tho_required, :only => [:reset_password, :announcements, :new_announcement, :update_announcement, :delete_announcement, :regcode, :section_toggle]
	before_action :admin_required, :only => [:upload_schedule, :activate]
	before_action :fetch_user, :only => [:profile, :update_user, :activate, :reset_password, :reset_photo, :regcode]
	before_action :fetch_announcement, :only => [:announcement, :update_announcement, :delete_announcement]
	
	def users
		render json: {status: 'ok', users: User.all.asc(:username).map { |x| x.decorate.admin_hash }}
	end
	
	def user
		search_text = params[:query].strip.downcase.gsub(/[^\w&\s-]/, '')
		user_query = User.search(params)
		render json: {status: 'ok', search_text: search_text, users: user_query.map{|x| x.decorate.admin_hash }}
	end

	def profile
		render json: {status: 'ok', user: @user.decorate.admin_hash}
	end
	
	def update_user
		roleErrors = []
		if params.has_key?(:role)
			newRole = User::Role.from_string(params[:role])
			
			# You cannot change your own role
			roleErrors.push('You cannot change your own role.') if @user.username == current_username && @user.role != newRole
			
			if @current_user.role == User::Role::MODERATOR
				# Moderators cannot ban/unban users
				if newRole == User::Role::BANNED || (@user.role == User::Role::BANNED && newRole != User::Role::BANNED)
					roleErrors.push('Only Admin and THO can ban or unban users.')
				end
				
				# Moderators cannot alter priviliged roles
				if @user.role != newRole && (@user.role >= User::Role::MODERATOR || newRole >= User::Role::MODERATOR)
					roleErrors.push('Only Admin and THO can change priviliged roles.')
				end
			elsif @current_user.role < User::Role::ADMIN
				if @user.role != newRole && (@user.role >= User::Role::ADMIN || newRole >= User::Role::ADMIN)
					roleErrors.push("Only Admin can grant or revoke the admin role.")
				end
			end
			
			@user.role = newRole
		end
		
		# @user.status = params[:status] if params.has_key? :status

		@user.display_name = params[:display_name] if params.has_key? :display_name
    if @user.display_name.blank?
      @user.display_name = @user.username
    end
    @user.email = params[:email] if params.has_key? :email
    @user.home_location = params[:home_location] if params.has_key? :home_location
    @user.real_name = params[:real_name] if params.has_key? :real_name
    @user.pronouns = params[:pronouns] if params.has_key? :pronouns
		@user.room_number = params[:room_number] if params.has_key? :room_number
		@user.mute_reason = params[:mute_reason] if params.has_key? :mute_reason
		@user.ban_reason = params[:ban_reason] if params.has_key? :ban_reason
		
		if !@user.valid? || roleErrors.count > 0
			roleErrors.each do |x|
				@user.errors.add(:role, x)
			end
			render status: :bad_request, json: {status: 'error', errors: @user.errors.messages} and return
		end

		@user.save
		render json: {status: 'ok', user: @user.decorate.admin_hash}
	end

	def regcode
		render json: {status: 'ok', registration_code: @user.registration_code}
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

	def reset_photo
		render json: @user.reset_photo
	end
	
	def announcements
		render json: {status: 'ok', announcements: Announcement.all.desc(:timestamp).map { |x| x.decorate.to_admin_hash(request_options) }}
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

    as_username = post_as_user(params)
    errors.push('Only admins may post as TwitarrTeam.') if (!is_admin? or as_username == "moderator")

    render status: :bad_request, json: {status: 'error', errors: errors} and return unless errors.length == 0
		
		announcement = Announcement.create(author: as_username, text: params[:text], timestamp: time, valid_until: valid_until, original_author: current_username)
		render json: {status: 'ok', announcement: announcement.decorate.to_admin_hash(request_options)}
	end

	def announcement
		render json: {status: 'ok', announcement: @announcement.decorate.to_admin_hash(request_options)}
	end

	def update_announcement
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
		
		@announcement.text = params[:text]
		@announcement.valid_until = valid_until
		
		if @announcement.save
			render json: {status: 'ok', announcement: @announcement.decorate.to_admin_hash(request_options)}
		else
			render status: :bad_request, json: {status: 'error', errors: @announcement.errors.full_messages}
		end
	end

	def delete_announcement
		if @announcement.destroy
      render json: {status: 'ok'}
    else
      render status: :bad_request, json: {status: 'error', error: @announcement.errors.full_messages}
    end
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

	def sections
		render json: {status: 'ok', sections: Section.all.map{ |x| x.decorate.to_hash}}
	end

	def section_toggle
		begin
			result = Section.toggle(params[:name], params[:enabled])
			render json: {status: 'ok', section: result.decorate.to_hash}
		rescue => e
			render status: :not_found, json: {status: 'error', error: "Section not found."}
		end
	end

	private
	def fetch_user
    @user = User.get params[:username]
    render status: :not_found, json: {status: 'error', error: 'User not found.'} and return unless @user
	end
	
	def fetch_announcement
		begin
			@announcement = Announcement.find(params[:id])
		rescue
			render status: :not_found, json: {status: 'error', error: 'Announcement not found.'} and return
		end
  end
end