require 'digest'
require 'singleton'

class PhotoStore
  include Singleton

  SMALL_PROFILE_PHOTO_SIZE = 200
  SMALL_IMAGE_SIZE = 200
  MEDIUM_IMAGE_SIZE = 800

  IMAGE_MAX_FILESIZE = 10000000 # 10MB

  def upload(temp_file, uploader)
    return { status: 'error', error: 'File must be uploaded as form-data.'} unless temp_file.is_a? ActionDispatch::Http::UploadedFile
    temp_file = UploadFile.new(temp_file)
    return { status: 'error', error: 'File was not an allowed image type - only jpg, gif, and png accepted.' } unless temp_file.photo_type?
    return { status: 'error', error: 'File exceeds maximum file size of 10MB.' } if temp_file.tempfile.size > IMAGE_MAX_FILESIZE

    existing_photo = PhotoMetadata.where(md5_hash: temp_file.md5_hash, uploader: uploader).first
    return { status: 'ok', photo: existing_photo.id.to_s } unless existing_photo.nil?

    begin
      img = read_image(temp_file.tempfile.path)
    rescue => e
      return { status: 'error', error: "Photo could not be read: #{e}" }
    end

    photo = store(temp_file, uploader)
    tmp_path = "#{Rails.root}/tmp/#{photo.store_filename}"

    sizes = {}
    sizes[:full] = "#{img.width}x#{img.height}"

    tmp = img
    tmp = tmp.thumbnail(MEDIUM_IMAGE_SIZE) if(tmp.width > MEDIUM_IMAGE_SIZE || tmp.height > MEDIUM_IMAGE_SIZE)
    sizes[:medium_thumb] = "#{tmp.width}x#{tmp.height}"
    tmp.save tmp_path
    FileUtils.move tmp_path, md_thumb_path(photo.store_filename)

    tmp = img.cropped_thumbnail(SMALL_IMAGE_SIZE)
    sizes[:small_thumb] = "#{tmp.width}x#{tmp.height}"
    tmp.save tmp_path
    FileUtils.move tmp_path, sm_thumb_path(photo.store_filename)

    photo.sizes = sizes
    photo.save
    { status: 'ok', photo: photo.id.to_s }
  end

  def read_image(temp_file)
    img = ImageVoodoo.with_image(temp_file)
    img.correct_orientation
  end

  def upload_profile_photo(temp_file, username)
    return { status: 'error', error: 'File must be uploaded as form-data'} unless temp_file.is_a? ActionDispatch::Http::UploadedFile
    temp_file = UploadFile.new(temp_file)
    return { status: 'error', error: 'File was not an allowed image type - only jpg, gif, and png accepted.' } unless temp_file.photo_type?
    return { status: 'error', error: 'File exceeds maximum file size of 10MB.' } if temp_file.tempfile.size > IMAGE_MAX_FILESIZE
    
    begin
      img = read_image(temp_file.tempfile.path)
    rescue => e
      return { status: 'error', error: "Photo could not be read: #{e}" }
    end

    tmp_store_path = "#{Rails.root}/tmp/#{username}.jpg"
    img.save tmp_store_path
    FileUtils.move tmp_store_path, PhotoStore.instance.full_profile_path(username)

    img.cropped_thumbnail(SMALL_PROFILE_PHOTO_SIZE).save tmp_store_path
    FileUtils.move tmp_store_path, PhotoStore.instance.small_profile_path(username)

    { status: 'ok', md5_hash: temp_file.md5_hash }
  end

  def reset_profile_photo(username)
    identicon = Identicon.create(username)
    tmp_store_path = "#{Rails.root}/tmp/#{username}.jpg"
    identicon.write tmp_store_path
    FileUtils.move tmp_store_path, PhotoStore.instance.full_profile_path(username)
    identicon.resize_to_fill(SMALL_PROFILE_PHOTO_SIZE).write tmp_store_path
    small_profile_path = PhotoStore.instance.small_profile_path(username)
    FileUtils.move tmp_store_path, small_profile_path
    { status: 'ok', md5_hash: Digest::MD5.file(small_profile_path).hexdigest }
  end

  def store(file, uploader)
    animated_image = ImageHelpers::AnimatedImage.is_animated file.tempfile.path
    photo = PhotoMetadata.new uploader: uploader,
                              content_type: file.content_type,
                              store_filename: file.filename,
                              upload_time: Time.now,
                              md5_hash: file.md5_hash,
                              animated: animated_image
    FileUtils.copy file.tempfile, photo_path(photo.store_filename)
    photo
  end

  def reindex_photos
    PhotoMetadata.each do |photo|
      puts photo.store_filename
      begin
        img = read_image(photo_path(photo.store_filename))

        tmp_path = "#{Rails.root}/tmp/#{photo.store_filename}"
        tmp = img.cropped_thumbnail(SMALL_IMAGE_SIZE).save tmp_path

        FileUtils.move tmp_path, sm_thumb_path(photo.store_filename)
      rescue => e
        puts e
      end
    end
  end

  def reindex_profiles
    User.each do |user|
      puts user.username
      begin
        img = read_image(full_profile_path(user.username))

        tmp_store_path = "#{Rails.root}/tmp/#{user.username}.jpg"
        img.cropped_thumbnail(SMALL_PROFILE_PHOTO_SIZE).save tmp_store_path
        
        FileUtils.move tmp_store_path, small_profile_path(user.username)
      rescue => e
        puts e
      end
    end
  end

  def initialize
    @root = Rails.root.join(Rails.configuration.photo_store)

    @full = @root + 'full'
    @thumb = @root + 'thumb'
    @profiles = @root + 'profiles/'
    @profiles_small = @profiles + 'small'
    @profiles_full = @profiles + 'full'
    @full.mkdir unless @full.exist?
    @thumb.mkdir unless @thumb.exist?
    @profiles.mkdir unless @profiles.exist?
    @profiles_small.mkdir unless @profiles_small.exist?
    @profiles_full.mkdir unless @profiles_full.exist?
  end

  def photo_path(filename)
    (build_directory(@full, filename) + filename).to_s
  end

  def sm_thumb_path(filename)
    (build_directory(@thumb, filename) + ('sm_' + filename)).to_s
  end

  def md_thumb_path(filename)
    (build_directory(@thumb, filename) + ('md_' + filename)).to_s
  end

  def small_profile_path(username)
    @profiles_small + "#{username}.jpg"
  end

  def full_profile_path(username)
    @profiles_full + "#{username}.jpg"
  end

  @@mutex = Mutex.new

  def build_directory(root_path, filename)
    @@mutex.synchronize do
      first = root_path + filename[0]
      first.mkdir unless first.exist?
      second = first + filename[1]
      second.mkdir unless second.exist?
      second
    end
  end

  class UploadFile
    PHOTO_CONTENT_TYPES = %w(image/png image/jpeg image/gif).freeze

    def initialize(file)
      Rails.logger.debug('content type = ' + file.content_type)
      if file.content_type == 'image/png'
        ext = '.png'
      elsif file.content_type == 'image/jpeg'
        ext = '.jpg'
      elsif file.content_type == 'image/gif'
        ext = '.gif'
      end
      file.original_filename = SecureRandom.uuid.to_s + ext
      Rails.logger.debug('filename = ' + file.original_filename)
      @file = file
    end

    def photo_type?
      return true if PHOTO_CONTENT_TYPES.include?(content_type)
      false
    end

    def tempfile
      @file.tempfile
    end

    def md5_hash
      @hash ||= Digest::MD5.file(@file.tempfile).hexdigest
    end

    def filename
      @file.original_filename
    end

    def content_type
      @file.content_type
    end
  end
end
