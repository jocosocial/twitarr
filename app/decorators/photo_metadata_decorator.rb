# frozen_string_literal: true

class PhotoMetadataDecorator < Draper::Decorator
  delegate_all

  def to_hash
    {
      id: id.to_s,
      animated:,
      store_filename:,
      md5_hash:,
      content_type:,
      uploader: user.username,
      upload_time: created_at.to_ms,
      sizes:
    }
  end
end
