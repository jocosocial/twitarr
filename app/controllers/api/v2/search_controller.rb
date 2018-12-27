class API::V2::SearchController < ApplicationController
  include Twitter::Extractor

  # noinspection RailsParamDefResolve
  skip_before_action :verify_authenticity_token

  DETAILED_SEARCH_MAX = 50

  def all
    return unless params_valid?(params)
    params[:current_username] = current_username
    render json: {
      status: 'ok',
      query: params[:text],
      users: do_search(params, User) { |e| e.decorate.gui_hash },
      seamails: do_search(params, Seamail) { |e| e.decorate.to_meta_hash },
      tweets: do_search(params, StreamPost) { |e| e.decorate.to_hash(current_username, request_options) },
      forums: do_search(params, Forum) { |e| e.decorate.to_meta_hash },
      events: do_search(params, Event) { |e| e.decorate.to_hash }      
    }
  end

  def users
    return unless params_valid?(params)
    params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
    render json: {
      status: 'ok',
      query: params[:text],
      users: do_search(params, User) { |e| e.decorate.gui_hash }
    }
  end

  def tweets
    return unless params_valid?(params)
    params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
    render json: {
      status: 'ok',
      query: params[:text],
      tweets: do_search(params, StreamPost) { |e| e.decorate.to_hash(current_username, request_options) }
    }
  end

  def forums
    return unless params_valid?(params)
    params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
    render json: {
      status: 'ok',
      query: params[:text],
      forums: do_search(params, Forum) { |e| e.decorate.to_meta_hash }
    }
  end

  def events
    return unless params_valid?(params)
    params[:limit] = DETAILED_SEARCH_MAX unless params[:limit]
    render json: { 
      status: 'ok',
      query: params[:text],
      events: do_search(params, Event) { |e| e.decorate.to_hash }
    }
  end

  private
  def do_search(params, collection)
    query = collection.search(params)
    matches = query.map { |e| yield e }
    {matches: matches, count: query.length, more: query.has_more?}
  end

  def params_valid?(params)
    unless params[:text]
      render status: :bad_request, json: {error: 'Required parameter \'text\' not set.'}
      return false
    end
    return true
  end
end
