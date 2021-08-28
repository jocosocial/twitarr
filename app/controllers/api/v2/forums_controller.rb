# frozen_string_literal: true

module Api
  module V2
    class ForumsController < ApiController
      before_action :forums_enabled
      before_action :login_required, only: [:create, :new_post, :update_post, :delete_post, :react, :unreact, :mark_all_read]
      before_action :tho_required, only: [:sticky]
      before_action :moderator_required, only: [:delete, :locked]
      before_action :not_muted, only: [:create, :new_post, :update_post, :react]
      before_action :fetch_forum, only: [:show, :delete, :new_post, :load_post, :update_post, :delete_post, :sticky, :locked]
      before_action :fetch_post, only: [:load_post, :update_post, :delete_post, :react, :unreact, :show_reacts]
      before_action :check_locked, only: [:new_post, :update_post, :delete_post, :react, :unreact]

      def index
        page_size = (params[:limit] || Forum::PAGE_SIZE).to_i

        page = (params[:page] || 0).to_i

        errors = []
        errors.push 'Limit must be greater than zero.' if page_size <= 0

        errors.push 'Page must be greater than or equal to zero.' if page < 0

        query = Forum.all

        if logged_in?
          query = query.includes(:forum_views).references(:user_forum_views)
          if params.key?(:participated) && params[:participated].to_bool
            begin
              query = query.includes(:posts).where(forum_posts: { author: current_user.id }).references(:forum_posts)
            rescue ArgumentError => e
              errors.push e.message
            end
          end
        end

        if errors.count > 0
          render status: :bad_request, json: { status: 'error', errors: errors }
          return
        end

        thread_count = query.count
        query = query.order(sticky: :desc, last_post_time: :desc, id: :desc).offset(page * page_size).limit(page_size)
        page_count = (thread_count.to_f / page_size).ceil

        next_page = (page + 1 if thread_count > (page + 1) * page_size)
        prev_page = (page - 1 if page > 0)
        render json: {
            status: 'ok',
            forum_threads: query.map { |x| x.decorate.to_meta_hash(logged_in? ? current_user : nil, page_size) },
            next_page: next_page,
            prev_page: prev_page,
            thread_count: thread_count,
            page: page,
            page_count: page_count
        }
      end

      def show
        limit = (params[:limit] || Forum::PAGE_SIZE).to_i
        page = (params[:page] || 0).to_i

        errors = []
        errors.push 'Limit must be greater than zero.' if limit <= 0

        errors.push 'Page must be greater than or equal to zero.' if page < 0

        if errors.count > 0
          render status: :bad_request, json: { status: 'error', errors: errors }
          return
        end

        query = current_forum.decorate

        result = if params.key?(:page)
                   query.to_paginated_hash(page, limit, current_user, request_options)
                 else
                   query.to_hash(current_user, request_options)
                 end

        current_user.update_forum_view(params[:id]) if logged_in?

        render json: { status: 'ok', forum_thread: result }
      end

      def create
        forum = Forum.create_new_forum(post_as_user(params).id, params[:subject], params[:text], params[:photos], current_user.id)
        if forum.valid?
          render json: { status: 'ok', forum_thread: forum.decorate.to_hash(current_user, request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: forum.errors.full_messages }
        end
      end

      def delete
        if current_forum.destroy
          render json: { status: 'ok' }
        else
          render status: :bad_request, json: { status: 'error', errors: current_forum.errors.full_messages }
        end
      end

      def new_post
        post = ForumPost.new_post(params[:id], post_as_user(params).id, params[:text], params[:photos], current_user.id)
        if post.valid?
          post.save
          render json: { status: 'ok', forum_post: post.decorate.to_hash(current_user, nil, request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: post.errors.full_messages }
        end
      end

      def load_post
        render json: { status: 'ok', forum_post: current_post.decorate.to_hash(current_user, nil, request_options) }
      end

      def update_post
        unless (current_post.author == current_user.id) || tho?
          render status: :forbidden, json: { status: 'error', error: "You can not edit other users' posts." }
          return
        end

        current_post.text = params[:text]
        if current_post.valid?
          if params[:photos]
            current_post.post_photos.replace(params[:photos].map { |photo| PostPhoto.new(photo_metadata_id: photo) })
          else
            current_post.post_photos.destroy_all
          end
          current_post.save
          render json: { status: 'ok', forum_post: current_post.decorate.to_hash(current_user, nil, request_options) }
        else
          render status: :bad_request, json: { status: 'error', errors: current_post.errors.full_messages }
        end
      end

      def delete_post
        unless (current_post.author == current_user.id) || moderator?
          render status: :forbidden, json: { status: 'error', error: "You can not delete other users' posts." }
          return
        end

        current_post.destroy
        thread_deleted = current_forum.posts.count == 0

        render json: { status: 'ok', thread_deleted: thread_deleted }
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

        current_post.add_reaction(current_user.id, reaction.id)
        if current_post.valid?
          render json: { status: 'ok', reactions: BaseDecorator.reaction_summary(current_post.post_reactions, current_user.id) }
        else
          render status: :bad_request, json: { status: 'error', error: "Invalid reaction: #{params[:type]}" }
        end
      end

      def show_reacts
        render json: { status: 'ok', reactions: current_post.post_reactions.map { |x| x.decorate.to_hash } }
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

        current_post.remove_reaction(current_user.id, reaction.id)
        render json: { status: 'ok', reactions: BaseDecorator.reaction_summary(current_post.post_reactions, current_user.id) }
      end

      def sticky
        begin
          current_forum.sticky = params[:sticky].to_bool
        rescue ArgumentError => e
          render status: :bad_request, json: { status: 'error', error: e.message }
          return
        end
        if current_forum.valid? && current_forum.save
          render json: { status: 'ok', sticky: current_forum.sticky }
        else
          render status: :bad_request, json: { status: 'error', errors: current_forum.errors.full_messages }
        end
      end

      def locked
        begin
          current_forum.locked = params[:locked].to_bool
        rescue ArgumentError => e
          render status: :bad_request, json: { status: 'error', error: e.message }
          return
        end
        if current_forum.valid? && current_forum.save
          render json: { status: 'ok', locked: current_forum.locked }
        else
          render status: :bad_request, json: { status: 'error', errors: current_forum.errors.full_messages }
        end
      end

      def mark_all_read
        begin
          participated_only = params[:participated].to_bool
        rescue ArgumentError => e
          render status: :bad_request, json: { status: 'error', error: e.message }
          return
        end
        current_user.mark_all_forums_read(participated_only)
        render json: { status: 'ok' }
      end

      private

      def fetch_forum
        current_forum
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: { status: 'error', error: 'Forum thread not found.' }
      end

      def fetch_post
        current_post
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: { status: 'error', error: 'Post not found.' }
      end

      def current_forum
        @current_forum ||= Forum.find(params[:id])
      end

      def current_post
        if @current_forum
          @current_post ||= @current_forum.posts_with_data.find(params[:post_id])
        else
          @current_post ||= ForumPost.includes(:forum).references(:forums).find(params[:post_id])
          @current_forum ||= @current_post.forum
        end

        @current_post
      end

      def check_locked
        unless moderator?
          render status: :forbidden, json: { status: 'error', error: 'Forum thread is locked.' } if current_forum&.locked
        end
      end
    end
  end
end
