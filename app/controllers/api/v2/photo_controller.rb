require 'tempfile'
# noinspection RailsParamDefResolve,RubyResolve
class Api::V2::PhotoController < ApplicationController
  PAGE_LENGTH = 20
  before_action :login_required, :only => [:create, :destroy, :update]
  before_action :not_muted, :only => [:create, :update]
  before_action :admin_required, :only => [:index]
  before_action :fetch_photo, :except => [:index, :create]

  def fetch_photo
    begin
      @photo = PhotoMetadata.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render status: :not_found, json: {status: 'error', error: "Photo not found."}
    end
  end

  def index
    errors = []

    limit = (params[:limit] || PAGE_LENGTH).to_i
    if limit < 1
      errors.push "Limit must be greater than 0"
    end

    page = (params[:page] || 0).to_i
    if page < 0
      errors.push "Page must be greater than or equal to 0"
    end

    sort_by = (params[:sort_by] || 'upload_time').to_sym
    unless [:id, :animated, :store_filename, :md5_hash, :content_type, :uploader, :upload_time].include? sort_by
      errors.push "Invalid field name for sort_by"
    end

    order = (params[:order] || 'asc').to_sym
    unless [:asc, :desc].include? order
      errors.push "Order must be either asc or desc"
    end

    render status: :bad_request, json: {status:'error', errors: errors} and return unless errors.empty?

    query = PhotoMetadata.all.order_by([sort_by, order]).skip(limit * page).limit(limit)
    count = query.length
    render json: {status: 'ok', total_count: count, page: page, photos: query.map { |x| x.decorate.to_hash}}
  end

  def show
    render json: {status: 'ok', photo: @photo.decorate.to_hash}
  end

  def create
    if params[:file].blank? || !params[:file].is_a?(ActionDispatch::Http::UploadedFile)
      render status: :bad_request, json: {status: 'error', error: 'Must provide photo to upload.'} and return
    end

    results = PhotoStore.instance.upload(params[:file], current_username)

    if results.fetch(:status) == 'error'
      render status: :bad_request, json: results
    else
      photo = PhotoMetadata.find(results.fetch(:photo))
      render json: {status: "ok", photo: photo.decorate.to_hash}
    end
  end

  def destroy
    unless @photo.uploader == current_username or is_moderator?
      render status: :bad_request, json: {status: "error", error: "You can not delete other users' photos"} and return
    end

    begin
      Rails.logger.info 'deleting ' + PhotoStore.instance.photo_path(@photo.store_filename)
      File.delete PhotoStore.instance.photo_path(@photo.store_filename)
    rescue => e
      Rails.logger.error "Error deleting file: #{e.to_s}"
    end

    begin
      Rails.logger.info 'deleting ' + PhotoStore.instance.sm_thumb_path(@photo.store_filename)
      File.delete PhotoStore.instance.sm_thumb_path(@photo.store_filename)
    rescue => e
      Rails.logger.error "Error deleting file: #{e.to_s}"
    end

    begin
      Rails.logger.info 'deleting ' + PhotoStore.instance.md_thumb_path(@photo.store_filename)
      File.delete PhotoStore.instance.md_thumb_path(@photo.store_filename)
    rescue => e
      Rails.logger.error "Error deleting file: #{e.to_s}"
    end

    StreamPost.any_in(photo: @photo.id).update_all(photo: nil)

    Forum.where(:'fp.ph' => @photo.id.to_s).each {|forum|
      forum.posts.where(:ph => @photo.id.to_s).each {|post|
        post.ph.delete_at(post.ph.index @photo.id.to_s)
        post.save
      }
    }

    if @photo.destroy
      head :no_content, status: :ok and return
    else
      render status: :bad_request, json: { status: "error", errors: @photo.errors }
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
