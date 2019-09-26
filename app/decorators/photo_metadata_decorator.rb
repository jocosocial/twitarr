class PhotoMetadataDecorator < Draper::Decorator
  delegate_all

  def to_hash
    {
        id: id.to_s,
        animated: animated,
        store_filename: store_filename,
        md5_hash: md5_hash,
        content_type: content_type,
        uploader: user.username,
        upload_time: created_at.to_ms,
        sizes: sizes
    }
  end
end
