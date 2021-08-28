# frozen_string_literal: true

module Api
  module V2
    class SeamailController < ApiController
      before_action :seamail_enabled
      before_action :login_required
      before_action :not_muted, only: [:create, :new_message, :recipients]
      before_action :fetch_seamail, only: [:show, :new_message, :recipients]

      def fetch_seamail
        begin
          @seamail = Seamail.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render status: :not_found, json: { status: 'error', error: 'Seamail not found' }
          return
        end
        @user_seamail = @seamail.user_seamails.find_by(user_id: as_user.id)
        render status: :not_found, json: { status: 'error', error: 'Seamail not found' } unless @user_seamail
      end

      def as_user
        @as_user ||= post_as_user(params)
      end

      def index
        extra_query = {}
        counting_unread = false
        begin
          if params[:unread] && params[:unread].to_bool
            extra_query[:unread] = true
            counting_unread = true
          end
        rescue ArgumentError => e
          render status: :bad_request, json: { status: 'error', error: e.message }
          return
        end
        if params[:after]
          val = Time.from_param(params[:after])
          extra_query[:after] = val if val
        end

        mails = as_user.seamail_threads extra_query

        if @include_messages
          output = 'seamail_threads'
          options = request_options
          options[:exclude_read_messages] = true if @exclude_read_messages
          mails = mails.includes(seamail_messages: [:user, { user_seamails: :user }]).references(:seamail_messages, :users, :user_seamails).map { |x| x.decorate.to_hash(options, as_user.id, counting_unread) }
        else
          output = 'seamail_meta'
          mails = mails.map { |x| x.decorate.to_meta_hash(as_user.id, counting_unread) }
        end

        render json: { status: 'ok', output => mails, last_checked: Time.now.to_ms }
      end

      def threads
        @include_messages = true
        @exclude_read_messages = true if params[:exclude_read_messages]
        index
      end

      def show
        mails = @seamail.decorate.to_hash(request_options, as_user.id, false, @user_seamail.last_viewed)
        @user_seamail.update(last_viewed: DateTime.now) unless params[:skip_mark_read]
        render json: { status: 'ok', seamail: mails }
      end

      def create
        Rails.logger.info "Posting as user: #{as_user.username}"
        seamail = Seamail.create_new_seamail as_user.username, params[:users], params[:subject], params[:text], current_username
        if seamail.valid?
          render json: { status: 'ok', seamail: seamail.decorate.to_hash(request_options, as_user.id) }
        else
          render status: :bad_request, json: { status: 'error', errors: seamail.errors.full_messages }
        end
      end

      def new_message
        message = @seamail.add_message as_user.username, params[:text], current_username
        if message.valid?
          render json: { status: 'ok', seamail_message: message.decorate.to_hash(request_options, as_user.id) }
        else
          render status: :bad_request, json: { status: 'error', errors: message.errors.full_messages }
        end
      end

      def recipients
        # this ensures that the logged in user is also specified
        usernames = params[:users]
        usernames ||= []
        usernames << as_user.username unless usernames.include? as_user.username
        usernames = usernames.map(&:downcase).uniq
        @seamail.usernames = usernames

        if @seamail.valid?
          @seamail.save!
          render json: { status: 'ok', seamail_meta: @seamail.decorate.to_meta_hash(as_user.id) }
        else
          render status: :bad_request, json: { status: 'error', errors: @seamail.errors.full_messages }
        end
      end
    end
  end
end
