require 'tempfile'

module Api
  module V2
    class PhotoController < ApiController
      PAGE_LENGTH = 20
      before_action :login_required, only: [:create, :destroy]
      before_action :not_muted, only: [:create]
      before_action :admin_required, only: [:index]
      before_action :fetch_photo, except: [:index, :create]

      def fetch_photo
        @photo = PhotoMetadata.includes(:user).references(:users).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render status: :not_found, json: { status: 'error', error: 'Photo not found.' }
      end

      def index
        errors = []

        limit = (params[:limit] || PAGE_LENGTH).to_i
        errors.push 'Limit must be greater than 0' if limit < 1

        page = (params[:page] || 0).to_i
        errors.push 'Page must be greater than or equal to 0' if page < 0

        sort_by = (params[:sort_by] || 'created_at').to_sym
        errors.push 'Invalid field name for sort_by' unless [:id, :animated, :store_filename, :md5_hash, :content_type, :user_id, :created_at].include? sort_by

        order = (params[:order] || 'asc').to_sym
        errors.push 'Order must be either asc or desc' unless [:asc, :desc].include? order

        if errors.empty?
          query = PhotoMetadata.all.includes(:user).references(:users).order(sort_by => order).offset(limit * page).limit(limit)
          count = query.length
          render json: { status: 'ok', total_count: count, page: page, photos: query.map { |x| x.decorate.to_hash } }
        else
          render status: :bad_request, json: { status: 'error', errors: errors }
        end
      end

      def show
        render json: { status: 'ok', photo: @photo.decorate.to_hash }
      end

      def create
        if params[:file].blank? || !params[:file].is_a?(ActionDispatch::Http::UploadedFile)
          render status: :bad_request, json: { status: 'error', error: 'Must provide photo to upload.' }
          return
        end

        results = PhotoStore.instance.upload(params[:file], current_user.id)

        if results.fetch(:status) == 'error'
          render status: :bad_request, json: results
        else
          photo = PhotoMetadata.includes(:user).references(:users).find(results.fetch(:photo))
          render json: { status: 'ok', photo: photo.decorate.to_hash }
        end
      end

      def destroy
        unless (@photo.user_id == current_user.id) || moderator?
          render status: :bad_request, json: { status: 'error', error: 'You can not delete other users\' photos' }
          return
        end

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

        if @photo.destroy
          head(:no_content, status: :ok)
          return
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
