# frozen_string_literal: true

module Api
  module V2
    class AdminController < ApiController
      before_action :moderator_required, only: [:users, :user, :profile, :update_user, :reset_photo]
      before_action :tho_required, only: [:reset_password, :announcements, :new_announcement, :update_announcement, :delete_announcement, :regcode, :section_toggle, :clear_text_cache]
      before_action :admin_required, only: [:upload_schedule, :activate]
      before_action :fetch_user, only: [:profile, :update_user, :activate, :reset_password, :reset_photo, :regcode]
      before_action :fetch_announcement, only: [:announcement, :update_announcement, :delete_announcement]

      def users
        render json: { status: 'ok', users: User.all.asc(:username).map { |x| x.decorate.admin_hash } }
      end

      def user
        search_text = params[:query].strip.downcase.gsub(/[^\w&\s-]/, '')
        user_query = User.search(params)
        render json: { status: 'ok', search_text:, users: user_query.map { |x| x.decorate.admin_hash } }
      end

      def profile
        render json: { status: 'ok', user: @user.decorate.admin_hash }
      end

      def update_user
        role_errors = []

        old_role = @user.role
        new_role = @user.role

        if params.key?(:role)
          new_role = User::Role.from_string(params[:role])

          if old_role != new_role
            # You cannot change your own role
            role_errors.push('You cannot change your own role.') if @user.username == current_username

            if @current_user.role == User::Role::MODERATOR
              # Moderators cannot ban/un-ban users
              role_errors.push('Only Admin and THO can ban or un-ban users.') if new_role == User::Role::BANNED || (old_role == User::Role::BANNED && new_role != User::Role::BANNED)

              # Moderators cannot alter privileged roles
              role_errors.push('Only Admin and THO can change privileged roles.') if old_role >= User::Role::MODERATOR || new_role >= User::Role::MODERATOR
            elsif @current_user.role < User::Role::ADMIN
              role_errors.push('Only Admin can grant or revoke the admin role.') if old_role >= User::Role::ADMIN || new_role >= User::Role::ADMIN
            end

            @user.role = new_role
          end
        end

        # @user.status = params[:status] if params.has_key? :status

        @user.display_name = params[:display_name] if params.key? :display_name
        @user.display_name = @user.username if @user.display_name.blank?
        @user.email = params[:email] if params.key? :email
        @user.home_location = params[:home_location] if params.key? :home_location
        @user.real_name = params[:real_name] if params.key? :real_name
        @user.pronouns = params[:pronouns] if params.key? :pronouns
        @user.show_pronouns = params[:show_pronouns].to_bool if params.key? :show_pronouns
        @user.room_number = params[:room_number] if params.key? :room_number
        @user.mute_reason = params[:mute_reason] if params.key? :mute_reason
        @user.ban_reason = params[:ban_reason] if params.key? :ban_reason

        if !@user.valid? || role_errors.count.positive?
          role_errors.each do |x|
            @user.errors.add(:role, x)
          end
          render status: :bad_request, json: { status: 'error', errors: @user.errors.messages }
          return
        end

        @user.save
        @user.process_role_change(old_role, new_role, current_username) if old_role != new_role

        render json: { status: 'ok', user: @user.decorate.admin_hash }
      end

      def regcode
        render json: { status: 'ok', registration_code: @user.registration_code }
      end

      def activate
        @user.status = User::ACTIVE_STATUS
        @user.save
        render json: { status: 'ok', user: @user.decorate.admin_hash }
      end

      def reset_password
        @user.change_password(User::RESET_PASSWORD)
        @user.save
        render json: { status: 'ok' }
      end

      def reset_photo
        render json: @user.reset_photo
      end

      def announcements
        render json: { status: 'ok', announcements: Announcement.all.order(created_at: :desc).map { |x| x.decorate.to_admin_hash(request_options) } }
      end

      def new_announcement
        time = Time.zone.now
        errors = []

        errors.push('Text is required.') if params[:text].blank?

        begin
          valid_until = Time.from_param(params[:valid_until])
        rescue StandardError
          errors.push('Unable to parse valid until.')
        else
          errors.push('Valid until must be in the future.') unless valid_until > time
        end

        as_user = post_as_user(params)
        errors.push('Only admins may post as TwitarrTeam.') if !admin? || (as_user.id == moderator_user.id)

        if errors.empty?
          announcement = Announcement.create(author: as_user.id, text: params[:text], valid_until:, original_author: current_user.id)
          render json: { status: 'ok', announcement: announcement.decorate.to_admin_hash(request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: }
        end
      end

      def announcement
        render json: { status: 'ok', announcement: @announcement.decorate.to_admin_hash(request_options) }
      end

      def update_announcement
        time = Time.zone.now
        errors = []

        errors.push('Text is required.') if params[:text].blank?

        begin
          valid_until = Time.from_param(params[:valid_until])
        rescue StandardError
          errors.push('Unable to parse valid until.')
        else
          errors.push('Valid until must be in the future.') unless valid_until > time
        end

        if errors.any?
          render status: :bad_request, json: { status: 'error', errors: }
          return
        end

        @announcement.text = params[:text]
        @announcement.valid_until = valid_until

        if @announcement.save
          render json: { status: 'ok', announcement: @announcement.decorate.to_admin_hash(request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: @announcement.errors.full_messages }
        end
      end

      def delete_announcement
        if @announcement.destroy
          render json: { status: 'ok' }
        else
          render status: :bad_request, json: { status: 'error', error: @announcement.errors.full_messages }
        end
      end

      def upload_schedule
        begin
          upload = params[:schedule].tempfile.read
          temp = upload.gsub(/&amp;/, '&').gsub(/(?<!\\);/, '\;')
          Icalendar::Calendar.parse(temp).first.events.map { |x| Event.create_from_ics x }
        rescue StandardError => e
          render status: :bad_request, json: { status: 'error', error: "Unable to parse schedule: #{e.message}" }
          return
        end
        render json: { status: 'ok' }
      end

      def sections
        query = Section.all
        if params[:category]
          categories = ['global', params[:category]]
          query = query.where(category: categories)
        end

        render json: { status: 'ok', sections: query.map { |x| x.decorate.to_hash } }
      end

      def section_toggle
        result = Section.toggle(params[:name], params[:enabled])
        render json: { status: 'ok', section: result.decorate.to_hash }
      rescue StandardError
        render status: :not_found, json: { status: 'error', error: 'Section not found.' }
      end

      def clear_text_cache
        Dir.glob(Rails.root.join('public/text/*.json')).each do |file|
          Rails.cache.delete("file:#{File.basename(file)}")
        end
        render json: { status: 'ok' }
      end

      private

      def fetch_user
        @user = User.get params[:username]
        render status: :not_found, json: { status: 'error', error: 'User not found.' } unless @user
      end

      def fetch_announcement
        @announcement = Announcement.find(params[:id])
      rescue StandardError
        render status: :not_found, json: { status: 'error', error: 'Announcement not found.' }
      end
    end
  end
end
