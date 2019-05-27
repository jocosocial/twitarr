class Api::V2::AdminController < ApplicationController
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
    sendMutedMessage = false
    sendUnmutedMessage = false

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

      sendMutedMessage = (newRole == User::Role::MUTED && @user.role != User::Role::MUTED)
      sendUnmutedMessage = (newRole == User::Role::USER && @user.role == User::Role::MUTED)
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

    if sendMutedMessage
      subject = 'You have been muted'
      message = "Hello #{@user.username},\n\nThis is an automated message letting you know that you have been muted. \
        While you are muted, you will be unable to make any posts, send any seamail, or update your profile. \
        It is likely that this muting is temporary, especially if this is the first time you have been muted.\n\n \
        You may be wondering why this has happened. Maybe a post you made was in violation of the Code of Conduct. \
        Maybe a moderator thinks a thread was getting out of hand, and is doing some clean-up. Whatever the reason, it's not \
        personal, it's just a moderator doing what they think best for the overall health of Twit-arr.\n\n \
        When muting happens, the moderator is required to enter a reason. Here is the reason that was provided for your mute: \
        \n\n#{@user.mute_reason}\n\n \
        A moderator may also send you additional seamail (either in this thread or a new thread) if they would like to \
        provide you with more information. If you would like to discuss this with someone, please proceed to the info desk. \
        They will be able to put you in touch with someone from the moderation team.\n\n \
        Bleep bloop,\n \
        The Twit-arr Robot"

      begin
        seamail = Seamail.find(@user.mute_thread)
        seamail.add_message 'moderator', message, current_username
      rescue
        seamail = Seamail.create_new_seamail 'moderator', [@user.username], subject, message, current_username
        @user.mute_thread = seamail.id.to_s
        @user.save
      end
    end

    if sendUnmutedMessage
      message = "Hello #{@user.username},\n\n \
      Good news! You have been unmuted. Please continue to enjoy your Twit-arr experience! \n\n \
      Bleep bloop, \n\
      The Twit-arr Robot"

      begin
        seamail = Seamail.find(@user.mute_thread)
      rescue
        subject = 'You have been unmuted'
        seamail = Seamail.create_new_seamail 'moderator', [@user.username], subject, message, current_username
        @user.mute_thread = seamail.id.to_s
        @user.save
      end
      seamail.add_message 'moderator', message, current_username
    end

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
