module Api
  module V2
    class SearchController < ApiController
      include Twitter::TwitterText::Extractor

      before_action :search_enabled
      before_action :profile_enabled, only: [:users]
      before_action :seamail_enabled, only: [:seamails]
      before_action :stream_enabled, only: [:tweets]
      before_action :forums_enabled, only: [:forums]
      before_action :events_enabled, only: [:events]

      DETAILED_SEARCH_MAX = 20

      def all
        return unless params_valid?(params)

        params[:current_user_id] = current_user&.id
        render json: {
          status: 'ok',
          query: params[:query],
          users:  do_search(params, User, Section.enabled?(:user_profile)) { |e| e.decorate.gui_hash },
          seamails: do_search(params, Seamail, Section.enabled?(:seamail)) { |e| e.decorate.to_meta_hash(current_user.id) },
          tweets: do_search(params, StreamPost, Section.enabled?(:stream)) { |e| e.decorate.to_hash(current_user, request_options) },
          forums: do_search(params, Forum, Section.enabled?(:forums)) { |e| e.decorate.to_meta_hash(current_user) },
          events: do_search(params, Event, Section.enabled?(:calendar)) { |e| e.decorate.to_hash(current_user, request_options) }
        }
      end

      def users
        return unless params_valid?(params)

        params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
        render json: {
          status: 'ok',
          query: params[:query],
          users: do_search(params, User) { |e| e.decorate.gui_hash }
        }
      end

      def seamails
        return unless params_valid?(params)

        params[:current_user_id] = current_user&.id
        params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
        render json: {
          status: 'ok',
          query: params[:query],
          seamails: do_search(params, Seamail) { |e| e.decorate.to_meta_hash(current_user&.id) }
        }
      end

      def tweets
        return unless params_valid?(params)

        params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
        render json: {
          status: 'ok',
          query: params[:query],
          tweets: do_search(params, StreamPost) { |e| e.decorate.to_hash(current_user, request_options) }
        }
      end

      def forums
        return unless params_valid?(params)

        params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
        render json: {
          status: 'ok',
          query: params[:query],
          forums: do_search(params, Forum) { |e| e.decorate.to_meta_hash(current_user) }
        }
      end

      def events
        return unless params_valid?(params)

        params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
        render json: {
          status: 'ok',
          query: params[:query],
          events: do_search(params, Event) { |e| e.decorate.to_hash(current_username, request_options) }
        }
      end

      private

      def do_search(params, collection, enabled = true)
        if enabled
          query = collection.search(params)
          count = query.limit(nil).count
          matches = query.map { |e| yield e }
          more = count > (query.limit_value + (query.offset_value || 0))
          { matches: matches, count: count, more: more }
        else
          { matches: [], count: 0, more: false }
        end
      end

      def params_valid?(params)
        errors = []
        errors.push 'Required parameter \'query\' not set.' unless params[:query]

        errors.push 'Limit must be greater than 0.' if !params[:limit].nil? && params[:limit].to_i < 1

        errors.push 'Page must be greater than or equal to 0.' if !params[:page].nil? && params[:page].to_i < 0

        if errors.count > 0
          render status: :bad_request, json: { status: 'error', errors: errors }
          return false
        end
        true
      end
    end
  end
end
