# frozen_string_literal: true

module Api
  module V2
    class AlertsController < ApiController
      before_action :login_required, only: [:last_checked]

      def index
        current_time = Time.zone.now

        announcements = Announcement.valid_announcements.map { |x| x.decorate.to_hash(request_options) }
        if logged_in?
          tweet_mentions = StreamPost.view_mentions(query: current_username, after: current_user[:last_viewed_alerts],
                                                    mentions_only: true).map { |p| p.decorate.to_hash(current_user, request_options) }

          forum_mentions = Forum.view_mentions(query: current_username, after: current_user[:last_viewed_alerts],
                                               mentions_only: true).map { |p| p.decorate.to_meta_hash(current_user) }

          unread_seamail = current_user.seamail_threads(unread: true).map { |m| m.decorate.to_meta_hash(current_user.id, true) }

          upcoming_events = current_user.upcoming_events(true).map { |e| e.decorate.to_hash(current_user, request_options) }

          unless params[:no_reset]
            current_user.reset_last_viewed_alerts(current_time)
            current_user.save!
          end
          last_checked_time = current_user[:last_viewed_alerts]
        else
          last_checked_time = session[:last_viewed_alerts] || Time.from_param(params[:last_checked_time]) || Time.zone.at(0)
          tweet_mentions = []
          forum_mentions = []
          unread_seamail = []
          upcoming_events = []
          unless params[:no_reset]
            session[:last_viewed_alerts] = current_time
            last_checked_time = session[:last_viewed_alerts]
          end
        end
        render json: { status: 'ok', announcements:, tweet_mentions:, forum_mentions:,
                       unread_seamail:, upcoming_events:, last_checked_time: last_checked_time.to_ms, query_time: current_time.to_ms }
      end

      def check
        if logged_in?
          render json: { status: 'ok', user_alerts: current_user.decorate.alerts_meta }
        else
          last_checked_time = session[:last_viewed_alerts] || Time.from_param(params[:last_checked_time]) || Time.zone.at(0)
          render json: { status: 'ok', user_alerts: { unnoticed_announcements: Announcement.new_announcements(last_checked_time).count } }
        end
      end

      def last_checked
        begin
          last_checked_time = Time.from_param(params[:last_checked_time])
        rescue StandardError
          render status: :bad_request, json: { status: 'error', error: 'Unable to parse timestamp.' }
          return
        end

        # if last_checked_time >= Time.now + 1.minute
        #   render status: :bad_request, json: { status: 'error', error: 'Timestamp must be in the past.' }
        #   return
        # end

        current_user.reset_last_viewed_alerts(last_checked_time)
        current_user.save!

        render json: { status: 'ok', last_checked_time: current_user.last_viewed_alerts.to_ms }
      end
    end
  end
end
