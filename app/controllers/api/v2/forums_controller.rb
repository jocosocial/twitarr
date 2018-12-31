class API::V2::ForumsController < ApplicationController
  skip_before_action :verify_authenticity_token

  POST_COUNT = 20
  before_filter :login_required, :only => [:create, :update_post, :like, :unlike, :react, :unreact]
  before_filter :fetch_forum, :except => [:index, :create, :show]
  
  def index
    page_size = (params[:limit] || POST_COUNT).to_i
    page = (params[:page] || 0).to_i

    if page_size <= 0
      page_size = POST_COUNT
    end

    if page < 0
      page = 0
    end

    query = Forum.all.desc(:last_post_time).offset(page * page_size).limit(page_size)
    page_count = (Forum.all.count.to_f / page_size).ceil

    next_page = if Forum.count > (page + 1) * page_size
                  page + 1
                else
                  nil
                end
    prev_page = if page > 0
                  page - 1
                else
                  nil
                end
    render json: {forum_meta: query.map { |x| x.decorate.to_meta_hash(current_user) }, next_page: next_page, prev_page: prev_page, pages: page_count}
  end

  def show
    limit = (params[:limit] || POST_COUNT).to_i
    start_loc = (params[:page] || 0).to_i

    if limit <= 0
      limit = POST_COUNT
    end

    if start_loc < 0
      start_loc = 0
    end

    query = Forum.find(params[:id]).decorate
    page_count = if params.has_key?(:page)
                    (query.posts.count.to_f / limit).ceil
                  else
                    nil
                  end
      
    if current_user
      if params.has_key?(:page)
        result = query.to_paginated_hash(start_loc, limit, current_user)
      else
        result = query.to_hash(current_user)
      end
    else
      if params.has_key?(:page)
        result = query.to_paginated_hash(start_loc, limit)
      else
        result = query.to_hash()
      end
    end

    current_user.update_forum_view(params[:id]) if logged_in?

    render json: {forum: result, pages: page_count}
  end

  def create
    forum = Forum.create_new_forum current_username, params[:subject], params[:text], params[:photos]
    if forum.valid?
      render json: {forum_meta: forum.decorate.to_meta_hash}
    else
      render json: {errors: forum.errors.full_messages}
    end
  end

  def new_post
    post = @forum.add_post current_username, params[:text], params[:photos]
    if post.valid?
      @forum.save
      render json: {forum_post: post.decorate.to_hash(current_user, nil, request_options)}
    else
      render json: {errors: post.errors.full_messages}
    end
  end

  def like
    post = @forum.posts.find(params[:post_id])
    post = post.add_to_set likes: current_username
    post.likes[post.likes.index(current_username)] = 'You'
    render json: {status: 'ok', likes: post.likes}
  end

  def show_likes
    post = @forum.posts.find(params[:post_id])
    render json: {status: 'ok', likes: post.likes }
  end

  def unlike
    post = @forum.posts.find(params[:post_id])
    post = post.pull likes: current_username
    render json: {status: 'ok', likes: post.likes}
  end

  def react
    unless params.has_key?(:type)
      render status: :bad_request, json: {error:'Reaction type must be included.'}
      return
    end
    post = @forum.posts.find(params[:post_id])
    post.add_reaction current_username, params[:type]
    if post.valid?
      render json: {status: 'ok', reactions: post.reactions}
    else
      render status: :bad_request, json: {error: "Invalid reaction: #{params[:type]}"}
    end
  end

  def show_reacts
    post = @forum.posts.find(params[:post_id])
    render json: {status: 'ok', reactions: post.reactions}
  end

  def unreact
    unless params.has_key?(:type)
      render status: :bad_request, json: {error:'Reaction type must be included.'}
      return
    end
    post = @forum.posts.find(params[:post_id])
    post.remove_reaction current_username, params[:type]
    render json: {status: 'ok', reactions: post.reactions}
  end
    
  private
  def fetch_forum
    @forum = Forum.find(params[:id])
  end
end
