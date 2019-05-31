class Api::V2::StreamController < ApplicationController
  PAGE_LENGTH = 20
  before_action :stream_enabled
  before_action :login_required,  :only => [:create, :destroy, :update, :react, :unreact]
  before_action :not_muted,  :only => [:create, :update, :react]
  before_action :fetch_post, :except => [:index, :create, :view_mention, :view_hash_tag]
  before_action :moderator_required, :only => [:locked]
  before_action :check_locked, :only => [:destroy, :update, :react, :unreact]

  def index
    params[:limit] = (params[:limit] || PAGE_LENGTH).to_i
    if params[:limit] < 1
      render status: :bad_request, json: {status:'error', error: "Limit must be greater than 0"} and return
    end

    query = {filter_author: params[:author], filter_hashtag: params[:hashtag], filter_mentions: params[:mentions], mentions_only: !params[:include_author]}

    begin
      param_newer_posts = params.has_key?(:newer_posts) && params[:newer_posts].to_bool

      if params.has_key?(:starred) and params[:starred].to_bool
        query[:filter_authors] = current_user.starred_users.reject { |x| x == current_username }
      end

      if params.has_key?(:reacted) and params[:reacted].to_bool
        query[:filter_reactions] = current_username
      end
    rescue ArgumentError => e
      render status: :bad_request, json: {status: 'error', error: e.message} and return
    end

    posts = nil
    newest = false
    sort = :desc

    if want_newest_posts?
      posts = newest_posts(query)
      newest = true
    elsif want_older_posts?
      posts = older_posts(query)
    elsif want_newer_posts?
      posts = newer_posts(query)
      sort = :asc # Change the sort direction so mongo returns the expected posts, instead of the oldest posts.
    end

    has_next_page = posts.count > params[:limit]
    posts = posts.limit(0 - params[:limit]).order_by(id: sort) # Limit needs to be negative, otherwise mongo will return additional posts

    posts = posts.map { |x| x } # Execute the query, so that our results are the expected size

    next_page = posts.last.nil? ? 0 : posts.last.timestamp.to_ms - 1

    if sort == :asc
      posts = posts.reverse # Restore sort direction of output to be by time descending - the opposite of what mongo gave us
      next_page = next_page + 1 # Since we're moving in the opposite direction, undo previous next_page calculation, and add an additional ms
    end

    results = {status: 'ok', stream_posts: posts.map{|x| x.decorate.to_hash(current_username, request_options)}, has_next_page: has_next_page, next_page: next_page}

    # If pulled the newest posts, and newer_posts=true, it means we are getting the newest posts,
    # and expect the next_page to be posts that are even further in the future.
    # Since we can't time travel, there are no newer posts, so set expected values for has_next_page and next_page.
    if newest && params.has_key?(:newer_posts) && param_newer_posts
      results.merge!({has_next_page: false, next_page: params[:start]+1})
    end

    render json: results
  end

  def show
    limit = (params[:limit] || PAGE_LENGTH).to_i
    start_loc = (params[:page] || 0).to_i
    if limit < 1 || start_loc < 0
      render status: :bad_request, json: {status:'error', error: "Limit must be greater than 0, Page must be greater than or equal to 0"} and return
    end
    show_options = request_options
    show_options[:remove] = [:parent_chain]
    has_next_page = StreamPost.where(parent_chain: params[:id]).count > ((start_loc + 1) * limit)
    children = StreamPost.where(parent_chain: params[:id]).limit(limit).skip(start_loc*limit).order_by(id: :asc).map { |x| x.decorate.to_hash(current_username, show_options) }
    post_result = @post.decorate.to_hash(current_username, request_options)
    if children and children.length > 0
      post_result[:children] = children
    end
    render json: {status: 'ok', post: post_result, has_next_page: has_next_page}
  end

  def locked
    begin
      lock = params[:locked].to_bool
    rescue ArgumentError => e
      render status: :bad_request, json: {status: 'error', error: e.message} and return
    end
    @post.locked = lock
    if @post.valid? && @post.save
      children = StreamPost.where(parent_chain: params[:id]).update_all(locked: lock)
      render json: {status: 'ok', locked: @post.locked}
    else
      render status: :bad_request, json: {status: 'error', errors: @post.errors.full_messages}
    end
  end

  def get
    result = @post.decorate.to_hash(current_username, request_options)
    render json: {status: 'ok', post: result}
  end

  def view_mention
    params[:mentions_only] = true

    params[:page] = (params[:page] || 0).to_i
    params[:limit] = (params[:limit] || PAGE_LENGTH).to_i
    if params[:limit] < 1 || params[:page] < 0
      render status: :bad_request, json: {status:'error', error: "Limit must be greater than 0, Page must be greater than or equal to 0"} and return
    end

    query = StreamPost.view_mentions params
    count = query.count
    has_next_page = count > ((params[:page] + 1) * params[:limit])
    render json: {status: 'ok', posts: query.map { |x| x.decorate.to_hash(current_username, request_options) }, total_mentions: count, has_next_page: has_next_page}
  end

  def view_hash_tag
    query_string = params[:query].downcase

    params[:page] = (params[:page] || 0).to_i
    params[:limit] = (params[:limit] || PAGE_LENGTH).to_i
    if params[:limit] < 1 || params[:page] < 0
      render status: :bad_request, json: {status:'error', error: "Limit must be greater than 0, Page must be greater than or equal to 0"} and return
    end

    query = StreamPost.view_hashtags params
    count = query.count
    has_next_page = count > ((params[:page] + 1) * params[:limit])
    render json: {status: 'ok', posts: query.map { |x| x.decorate.to_hash(current_username, request_options) }, total_mentions: count, has_next_page: has_next_page}
  end

  def delete
    unless @post.author == current_username or moderator?
      render status: :forbidden, json: {status:'error', error: "You can not delete other users' posts"} and return
    end
    if @post.destroy
      head :no_content, status: :ok
    else
      render status: :bad_request, json: {status:'error', errors: @post.errors}
    end
  end

  def create
    parent_chain = []
    parent_locked = false
    if params[:parent]
      parent = StreamPost.where(id: params[:parent]).first
      render status: :bad_request, json: {status:'error', error: "#{params[:parent]} is not a valid parent id"} and return unless parent
      render status: :forbidden, json: {status:'error', error: 'Post is locked.'} and return if parent.locked && !moderator?

      parent_chain = parent.parent_chain + [params[:parent]]
      parent_locked = parent.locked
    end

    post = StreamPost.create(text: params[:text], author: post_as_user(params), timestamp: Time.now, photo: params[:photo],
                             location: params[:location], parent_chain: parent_chain, original_author: current_username, locked: parent_locked)
    if post.valid?
      if params[:location]
        # if the location field was used, update the user's last known location
        current_user.current_location = params[:location]
        current_user.save
      end
      render json: {status: 'ok', stream_post: post.decorate.to_hash(current_username, request_options)}
    else
      render status: :bad_request, json: {status:'error', errors: post.errors.full_messages}
    end
  end

  # noinspection RubyResolve
  def update
    unless @post.author == current_username or tho?
      render status: :forbidden, json: {status:'error', error: "You can not modify other users' posts"} and return
    end

    unless params.has_key?(:text) or params.has_key?(:photo)
      render status: :bad_request, json: {status:'error', error: 'Update must modify either text or photo, or both.'} and return
    end

    @post.text = params[:text] if params.has_key? :text
    @post.photo = params[:photo] if params.has_key? :photo

    if @post.valid?
      @post.save
      render json: {status: 'ok', stream_post: @post.decorate.to_hash(current_username, request_options)}
    else
      render status: :bad_request, json: {status: 'error', errors: @post.errors.full_messages}
    end
  end

  def react
    unless params.has_key?(:type)
      render status: :bad_request, json: {status: 'error', error: 'Reaction type must be included.'}
      return
    end
    @post.add_reaction current_username, params[:type]
    if @post.valid?
      render json: {status: 'ok', reactions: BaseDecorator.reaction_summary(@post.reactions, current_username) }
    else
      render status: :bad_request, json: {status: 'error', error: "Invalid reaction: #{params[:type]}"}
    end
  end

  def show_reacts
    render json: {status: 'ok', reactions: @post.reactions.map {|x| x.decorate.to_hash } }
  end

  def unreact
    unless params.has_key?(:type)
      render status: :bad_request, json: {status: 'error', error: 'Reaction type must be included.'}
      return
    end
    @post.remove_reaction current_username, params[:type]
    render json: {status: 'ok', reactions: BaseDecorator.reaction_summary(@post.reactions, current_username) }
  end

  private
  ## The following functions are helpers for the finding of new posts in the stream

  def want_newest_posts?
    not params.has_key?(:start)
  end

  def newest_posts(query)
    start = Time.now.to_ms
    params[:start] = start
    older_posts(query)
  end

  def want_older_posts?
    params.has_key?(:start) and (!params.has_key?(:newer_posts) || !params[:newer_posts].to_bool)
  end

  def older_posts(query)
    posts = StreamPost.at_or_before(params[:start], query)
  end

  def want_newer_posts?
    params.has_key?(:start) and (params.has_key?(:newer_posts) && params[:newer_posts].to_bool)
  end

  def newer_posts(query)
    posts = StreamPost.at_or_after(params[:start], query)
  end

  def fetch_post
    begin
      @post = StreamPost.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status:'error', error: "Post not found."}
    end
  end

  def check_locked
    if !moderator?
      render status: :forbidden, json: {status: 'error', error: 'Post is locked.'} if @post.locked
    end
  end
end
