class Api::V2::SearchController < ApplicationController
  include Twitter::TwitterText::Extractor

  before_action :search_enabled

  DETAILED_SEARCH_MAX = 20

  def all
    return unless params_valid?(params)

    params[:current_username] = current_username
    render json: {
      status: 'ok',
      query: params[:query],
      users: do_search(params, User) { |e| e.decorate.gui_hash },
      seamails: do_search(params, Seamail) { |e| e.decorate.to_meta_hash(current_username) },
      tweets: do_search(params, StreamPost) { |e| e.decorate.to_hash(current_user, request_options) },
      forums: do_search(params, Forum) { |e| e.decorate.to_meta_hash(current_user) },
      events: do_search(params, Event) { |e| e.decorate.to_hash(current_username, request_options) }
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

    params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
    render json: {
      status: 'ok',
      query: params[:query],
      seamails: do_search(params, Seamail) { |e| e.decorate.to_meta_hash(current_username) }
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

  def do_search(params, collection)
    query = collection.search(params)
    matches = query.map { |e| yield e }
    { matches: matches, count: query.length, more: query.has_more? }
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
