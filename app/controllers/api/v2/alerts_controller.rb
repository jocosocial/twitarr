class API::V2::AlertsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    announcements = Announcement.valid_announcements.map { |x| x.decorate.to_hash(request_options) }
    if logged_in?
      tweet_mentions = StreamPost.view_mentions(query: current_username,
                                                mentions_only: true).map {|p| p.decorate.to_hash(current_username, request_options) }

      forum_mentions = Forum.view_mentions(query: current_username,
                                                mentions_only: true).map {|p| p.decorate.to_meta_hash }

      unread_seamail = current_user.seamails(unread: true).map{|m| m.decorate.to_meta_hash(current_username, true) }

      upcoming_events = current_user.upcoming_events(true).map{|e| e.decorate.to_hash(current_username, request_options) }

      unless params[:no_reset]
        current_user.reset_last_viewed_alerts
        current_user.save!
      end
      last_checked_time = current_user[:last_viewed_alerts]
    else
      last_checked_time = session[:last_viewed_alerts] || Time.from_param(params[:last_checked_time]) || Time.at(0)
      tweet_mentions = []
      forum_mentions = []
      unread_seamail = []
      upcoming_events = []
      unless params[:no_reset]
        session[:last_viewed_alerts] = Time.now
        last_checked_time = session[:last_viewed_alerts]
      end
    end
    render json: { status: "ok", announcements: announcements, tweet_mentions: tweet_mentions, forum_mentions: forum_mentions,
                unread_seamail: unread_seamail, upcoming_events: upcoming_events, last_checked_time: last_checked_time.to_ms }
  end

  def check
    if logged_in?
      render json: { status: 'ok', user_alerts: current_user.decorate.alerts_meta }
    else
      last_checked_time = session[:last_viewed_alerts] || Time.from_param(params[:last_checked_time]) || Time.at(0)
      render json: { status: 'ok', user_alerts: { unnoticed_announcements: Announcement.new_announcements(last_checked_time).count } }
    end

  end
end
