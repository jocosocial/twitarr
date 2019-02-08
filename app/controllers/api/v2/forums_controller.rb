class API::V2::ForumsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :login_required, :only => [:create, :new_post, :update_post, :delete_post, :react, :unreact]
  before_filter :not_muted, :only => [:create, :new_post, :update_post, :react]
  before_filter :fetch_forum, :except => [:index, :create]
  before_filter :fetch_post, :only => [:get_post, :update_post, :delete_post, :react, :unreact, :show_reacts]
  
  def index
    page_size = (params[:limit] || Forum::PAGE_SIZE).to_i
    page = (params[:page] || 0).to_i

    errors = []
    if page_size <= 0
      errors.push "Limit must be greater than zero."
    end

    if page < 0
      errors.push "Page must be greater than or equal to zero."
    end

    if errors.count > 0
      render status: :bad_request, json: {status: "error", errors: errors} and return
    end

    query = Forum.all.order_by(:sticky => :desc, :last_post_time => :desc).offset(page * page_size).limit(page_size)
    thread_count = Forum.all.count
    page_count = (thread_count.to_f / page_size).ceil

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
    render json: {status: 'ok', forum_threads: query.map { |x| x.decorate.to_meta_hash(current_user, page_size) }, next_page: next_page, prev_page: prev_page, thread_count: thread_count, page_count: page_count}
  end

  def show
    limit = (params[:limit] || Forum::PAGE_SIZE).to_i
    page = (params[:page] || 0).to_i
    
    errors = []
    if limit <= 0
      errors.push "Limit must be greater than zero."
    end

    if page < 0
      errors.push "Page must be greater than or equal to zero."
    end

    if errors.count > 0
      render status: :bad_request, json: {status: "error", errors: errors} and return
    end

    query = @forum.decorate
      
    if params.has_key?(:page)
      result = query.to_paginated_hash(page, limit, current_user, request_options)
    else
      result = query.to_hash(current_user, request_options)
    end

    current_user.update_forum_view(params[:id]) if logged_in?

    render json: {status: 'ok', forum_thread: result}
  end

  def create
    forum = Forum.create_new_forum current_username, params[:subject], params[:text], params[:photos]
    if forum.valid?
      render json: {status: 'ok', forum_thread: forum.decorate.to_hash(current_user, request_options)}
    else
      render json: {status: 'error', errors: forum.errors.full_messages}
    end
  end

  def new_post
    post = @forum.add_post current_username, params[:text], params[:photos]
    if post.valid?
      @forum.save
      render json: {status: 'ok', forum_post: post.decorate.to_hash(current_user, nil, request_options)}
    else
      render status: :bad_request, json: {status: 'error', errors: post.errors.full_messages}
    end
  end

  def get_post
    render json: {status: 'ok', forum_post: @post.decorate.to_hash(current_user, nil, request_options)}
  end

  def update_post
    unless @post.author == current_username or is_admin?
      render status: :forbidden, json: {status:'error', error: "You can not edit other users' posts."} and return
    end
    @post[:text] = params[:text]
    @post[:photos] = params[:photos]
    if @post.valid?
      @post.save
      render json: {status: 'ok', forum_post: @post.decorate.to_hash(current_user, nil, request_options)}
    else
      render status: :bad_request, json: {status: 'error', errors: @post.errors.full_messages} 
    end
  end

  def delete_post
    unless @post.author == current_username or is_admin?
      render status: :forbidden, json: {status:'error', error: "You can not delete other users' posts."} and return
    end
    thread_deleted = false
    @post.destroy
    if @forum.posts.count == 0
      @forum.destroy
      thread_deleted = true
    end
    render json: {status: 'ok', thread_deleted: thread_deleted}
  end

  def react
    render status: :bad_request, json: {status: 'error', error:'Reaction type must be included.'} and return unless params.has_key?(:type)
    @post.add_reaction current_username, params[:type]
    if @post.valid?
      render json: {status: 'ok', reactions: BaseDecorator.reaction_summary(@post.reactions, current_username)}
    else
      render status: :bad_request, json: {status: 'error', error: "Invalid reaction: #{params[:type]}"}
    end
  end

  def show_reacts
    render json: {status: 'ok', reactions: @post.reactions.map {|x| x.decorate.to_hash }}
  end

  def unreact
    render status: :bad_request, json: {status: 'error', error:'Reaction type must be included.'} and return unless params.has_key?(:type)
    @post.remove_reaction current_username, params[:type]
    render json: {status: 'ok', reactions: BaseDecorator.reaction_summary(@post.reactions, current_username)}
  end
    
  private
  def fetch_forum
    begin
      @forum = Forum.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status:'error', error: "Forum thread not found."}
    end
  end

  def fetch_post
    begin
      @post = @forum.posts.find(params[:post_id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status:'error', error: "Post not found."}
    end
  end
end
