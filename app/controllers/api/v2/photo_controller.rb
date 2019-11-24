require 'tempfile'
module Api
  module V2
    class PhotoController < ApplicationController
      PAGE_LENGTH = 20
      before_action :login_required, only: [:create, :destroy]
      before_action :not_muted, only: [:create]
      before_action :admin_required, only: [:index]
      before_action :fetch_photo, except: [:index, :create]

      def fetch_photo

        @photo = PhotoMetadata.find(params[:id])
      rescue Mongoid::Errors::DocumentNotFound
        render status: :not_found, json: { status: 'error', error: 'Photo not found.' }

      end

      def index
        errors = []

        limit = (params[:limit] || PAGE_LENGTH).to_i
        errors.push 'Limit must be greater than 0' if limit < 1

        page = (params[:page] || 0).to_i
        errors.push 'Page must be greater than or equal to 0' if page < 0

        sort_by = (params[:sort_by] || 'upload_time').to_sym
        errors.push 'Invalid field name for sort_by' unless [:id, :animated, :store_filename, :md5_hash, :content_type, :uploader, :upload_time].include? sort_by

        order = (params[:order] || 'asc').to_sym
        errors.push 'Order must be either asc or desc' unless [:asc, :desc].include? order

        render(status: :bad_request, json: { status: 'error', errors: errors }) && return unless errors.empty?

        query = PhotoMetadata.all.order_by([sort_by, order]).skip(limit * page).limit(limit)
        count = query.length
        render json: { status: 'ok', total_count: count, page: page, photos: query.map { |x| x.decorate.to_hash } }
      end

      def show
        render json: { status: 'ok', photo: @photo.decorate.to_hash }
      end

      def create
        render(status: :bad_request, json: { status: 'error', error: 'Must provide photo to upload.' }) && return if params[:file].blank? || !params[:file].is_a?(ActionDispatch::Http::UploadedFile)

        results = PhotoStore.instance.upload(params[:file], current_user.id)

        if results.fetch(:status) == 'error'
          render status: :bad_request, json: results
        else
          photo = PhotoMetadata.includes(:user).find(results.fetch(:photo))
          render json: { status: 'ok', photo: photo.decorate.to_hash }
        end
      end

      def destroy
        render(status: :bad_request, json: { status: 'error', error: "You can not delete other users' photos" }) && return unless (@photo.uploader == current_username) || moderator?

        begin
          Rails.logger.info 'deleting ' + PhotoStore.instance.photo_path(@photo.store_filename)
          File.delete PhotoStore.instance.photo_path(@photo.store_filename)
        rescue StandardError => e
          Rails.logger.error "Error deleting file: #{e}"
        end

        begin
          Rails.logger.info 'deleting ' + PhotoStore.instance.sm_thumb_path(@photo.store_filename)
          File.delete PhotoStore.instance.sm_thumb_path(@photo.store_filename)
        rescue StandardError => e
          Rails.logger.error "Error deleting file: #{e}"
        end

        begin
          Rails.logger.info 'deleting ' + PhotoStore.instance.md_thumb_path(@photo.store_filename)
          File.delete PhotoStore.instance.md_thumb_path(@photo.store_filename)
        rescue StandardError => e
          Rails.logger.error "Error deleting file: #{e}"
        end

        StreamPost.any_in(photo: @photo.id).update_all(photo: nil)

        Forum.where('fp.ph': @photo.id.to_s).each do |forum|
          forum.posts.where(ph: @photo.id.to_s).each do |post|
            post.ph.delete_at(post.ph.index(@photo.id.to_s))
            post.save
          end
        end

        if @photo.destroy
          head(:no_content, status: :ok) && return
        else
          render status: :bad_request, json: { status: 'error', errors: @photo.errors }
        end
      end

      def small_thumb
        expires_in 30.days, public: true
        response.headers['Etag'] = params[:id]
        send_file PhotoStore.instance.sm_thumb_path(@photo.store_filename)
      end

      def medium_thumb
        expires_in 30.days, public: true
        response.headers['Etag'] = params[:id]
        send_file PhotoStore.instance.md_thumb_path(@photo.store_filename)
      end

      def full
        expires_in 30.days, public: true
        response.headers['Etag'] = params[:id]
        send_file PhotoStore.instance.photo_path(@photo.store_filename), filename: @photo.store_filename, disposition: :inline
      end
    end
  end
end
