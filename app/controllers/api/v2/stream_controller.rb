module Api
  module V2
    class StreamController < ApiController
      PAGE_LENGTH = 20
      before_action :stream_enabled
      before_action :login_required, only: [:create, :delete, :update, :react, :unreact]
      before_action :not_muted, only: [:create, :update, :react]
      before_action :fetch_post, except: [:index, :create, :view_mention, :view_hash_tag]
      before_action :moderator_required, only: [:locked]
      before_action :check_locked, only: [:delete, :update, :react, :unreact]

      def index
        params[:limit] = (params[:limit] || PAGE_LENGTH).to_i
        if params[:limit] < 1
          render status: :bad_request, json: { status: 'error', error: 'Limit must be greater than 0' }
          return
        end

        query = { filter_author: params[:author], filter_hashtag: params[:hashtag], filter_mentions: params[:mentions], mentions_only: !params[:include_author] }

        begin
          param_newer_posts = params.key?(:newer_posts) && params[:newer_posts].to_bool
          query[:filter_authors] = current_user.starred_users.reject { |x| x.id == current_user.id }.pluck(:id) if params.key?(:starred) && params[:starred].to_bool
          query[:filter_reactions] = current_username if params.key?(:reacted) && params[:reacted].to_bool
        rescue ArgumentError => e
          render status: :bad_request, json: { status: 'error', error: e.message }
          return
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
          sort = :asc # Change the sort direction so the query returns the expected posts, instead of the oldest posts.
        end

        posts = posts.includes(:user, :post_reactions, :photo_metadata).references(:users, :post_reactions, :photo_metadata)

        has_next_page = posts.count > params[:limit]
        posts = posts.limit(params[:limit]).order(created_at: sort, id: sort)

        posts = posts.map { |x| x } # Execute the query, so that our results are the expected size

        next_page = posts.last.nil? ? 0 : posts.last.created_at.to_ms - 1

        if sort == :asc
          posts = posts.reverse # Restore sort direction of output to be by time descending - the opposite of what the query gave us
          next_page += 1 # Since we're moving in the opposite direction, undo previous next_page calculation, and add an additional ms
        end

        results = { status: 'ok', stream_posts: posts.map { |x| x.decorate.to_hash(current_user, request_options) }, has_next_page: has_next_page, next_page: next_page }

        # If pulled the newest posts, and newer_posts=true, it means we are getting the newest posts,
        # and expect the next_page to be posts that are even further in the future.
        # Since we can't time travel, there are no newer posts, so set expected values for has_next_page and next_page.
        results.merge!(has_next_page: false, next_page: params[:start] + 1) if newest && params.key?(:newer_posts) && param_newer_posts

        render json: results
      end

      def show
        limit = (params[:limit] || PAGE_LENGTH).to_i
        start_loc = (params[:page] || 0).to_i
        if limit < 1 || start_loc < 0
          render status: :bad_request, json: { status: 'error', error: 'Limit must be greater than 0, Page must be greater than or equal to 0' }
          return
        end

        show_options = request_options
        show_options[:remove] = [:parent_chain]

        thread = StreamPost.thread(params[:id])

        # TODO: Figure out if there's a way to combine these queries
        has_next_page = thread.count > ((start_loc + 1) * limit)
        children = thread.limit(limit).offset(start_loc * limit).order(created_at: :asc, id: :asc).map { |x| x.decorate.to_hash(current_user, show_options) }

        post_result = @post.decorate.to_hash(current_user, request_options)
        post_result[:children] = children unless children&.empty?

        render json: { status: 'ok', post: post_result, has_next_page: has_next_page }
      end

      def locked
        begin
          lock = params[:locked].to_bool
        rescue ArgumentError => e
          render status: :bad_request, json: { status: 'error', error: e.message }
          return
        end

        @post.locked = lock
        if @post.valid? && @post.save
          # rubocop:disable Rails/SkipsModelValidations
          StreamPost.thread(params[:id]).update_all(locked: lock)
          # rubocop:enable Rails/SkipsModelValidations
          render json: { status: 'ok', locked: @post.locked }
        else
          render status: :bad_request, json: { status: 'error', errors: @post.errors.full_messages }
        end
      end

      def get
        result = @post.decorate.to_hash(current_user, request_options)
        render json: { status: 'ok', post: result }
      end

      def view_mention
        params[:mentions_only] = true

        params[:page] = (params[:page] || 0).to_i
        params[:limit] = (params[:limit] || PAGE_LENGTH).to_i
        if params[:limit] < 1 || params[:page] < 0
          render status: :bad_request, json: { status: 'error', error: 'Limit must be greater than 0, Page must be greater than or equal to 0' }
          return
        end

        query = StreamPost.view_mentions params
        count = query.count
        has_next_page = count > ((params[:page] + 1) * params[:limit])
        render json: { status: 'ok', posts: query.map { |x| x.decorate.to_hash(current_user, request_options) }, total_mentions: count, has_next_page: has_next_page }
      end

      def view_hash_tag
        params[:query].downcase!

        params[:page] = (params[:page] || 0).to_i
        params[:limit] = (params[:limit] || PAGE_LENGTH).to_i
        if params[:limit] < 1 || params[:page] < 0
          render status: :bad_request, json: { status: 'error', error: 'Limit must be greater than 0, Page must be greater than or equal to 0' }
          return
        end

        query = StreamPost.view_hashtags(params)
        count = query.count
        has_next_page = count > ((params[:page] + 1) * params[:limit])
        render json: { status: 'ok', posts: query.map { |x| x.decorate.to_hash(current_user, request_options) }, total_mentions: count, has_next_page: has_next_page }
      end

      def delete
        unless @post.author == current_user.id || moderator?
          render status: :forbidden, json: { status: 'error', error: "You can not delete other users' posts" }
          return
        end

        if @post.destroy
          head :no_content, status: :ok
        else
          render status: :bad_request, json: { status: 'error', errors: @post.errors }
        end
      end

      def create
        parent_chain = []
        parent_locked = false
        if params[:parent]
          parent = StreamPost.find(params[:parent])
          unless parent
            render status: :bad_request, json: { status: 'error', error: "#{params[:parent]} is not a valid parent id" }
            return
          end

          if parent.locked && !moderator?
            render status: :forbidden, json: { status: 'error', error: 'Post is locked.' }
            return
          end

          parent_chain = parent.parent_chain << parent.id
          parent_locked = parent.locked
        end

        post = StreamPost.new(
          text: params[:text],
          author: post_as_user(params).id,
          parent_chain: parent_chain,
          location_id: params[:location],
          original_author: current_user.id,
          locked: parent_locked
        )
        post.post_photo = PostPhoto.new(photo_metadata_id: params[:photo]) if params.key?(:photo) && params[:photo].present?

        if post.valid?
          post.save
          if params[:location]
            # if the location field was used, update the user's last known location
            current_user.current_location = params[:location]
            current_user.save
          end
          render json: { status: 'ok', stream_post: post.decorate.to_hash(current_user, request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: post.errors.full_messages }
        end
      end

      # noinspection RubyResolve
      def update
        unless @post.author == current_user.id || tho?
          render status: :forbidden, json: { status: 'error', error: 'You can not modify other users\' posts' }
          return
        end

        unless params.key?(:text) || params.key?(:photo)
          render status: :bad_request, json: { status: 'error', error: 'Update must modify either text or photo, or both.' }
          return
        end

        @post.text = params[:text] if params.key?(:text)
        if params.key?(:photo)
          if params[:photo].blank?
            @post.post_photo.destroy
          elsif @post.post_photo&.photo_metadata_id != params[:photo]
            @post.post_photo = PostPhoto.create(photo_metadata_id: params[:photo])
          end
        end

        if @post.valid?
          @post.save
          render json: { status: 'ok', stream_post: @post.decorate.to_hash(current_user, request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: @post.errors.full_messages }
        end
      end

      def react
        unless params.key?(:type)
          render status: :bad_request, json: { status: 'error', error: 'Reaction type must be included.' }
          return
        end

        reaction = Reaction.find_by(name: params[:type])
        unless reaction
          render status: :bad_request, json: { status: 'error', error: "Invalid reaction: #{params[:type]}" }
          return
        end

        @post.add_reaction(current_user.id, reaction.id)
        if @post.valid?
          render json: { status: 'ok', reactions: BaseDecorator.reaction_summary(@post.post_reactions, current_user.id) }
        else
          render status: :bad_request, json: { status: 'error', error: "Invalid reaction: #{params[:type]}" }
        end
      end

      def show_reacts
        render json: { status: 'ok', reactions: @post.post_reactions.map { |x| x.decorate.to_hash } }
      end

      def unreact
        unless params.key?(:type)
          render status: :bad_request, json: { status: 'error', error: 'Reaction type must be included.' }
          return
        end

        reaction = Reaction.find_by(name: params[:type])
        unless reaction
          render status: :bad_request, json: { status: 'error', error: "Invalid reaction: #{params[:type]}" }
          return
        end

        @post.remove_reaction(current_user.id, reaction.id)
        render json: { status: 'ok', reactions: BaseDecorator.reaction_summary(@post.post_reactions, current_user.id) }
      end

      private

      ## The following functions are helpers for the finding of new posts in the stream

      def want_newest_posts?
        !params.key?(:start)
      end

      def newest_posts(query)
        start = Time.now.to_ms
        params[:start] = start
        older_posts(query)
      end

      def want_older_posts?
        params.key?(:start) && (!params.key?(:newer_posts) || !params[:newer_posts].to_bool)
      end

      def older_posts(query)
        StreamPost.at_or_before(params[:start], query)
      end

      def want_newer_posts?
        params.key?(:start) && (params.key?(:newer_posts) && params[:newer_posts].to_bool)
      end

      def newer_posts(query)
        StreamPost.at_or_after(params[:start], query)
      end

      def fetch_post
        @post = StreamPost.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: { status: 'error', error: 'Post not found.' }
      end

      def check_locked
        unless moderator?
          render status: :forbidden, json: { status: 'error', error: 'Post is locked.' } if @post.locked
        end
      end
    end
  end
end
