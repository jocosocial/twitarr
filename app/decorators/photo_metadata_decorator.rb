class PhotoMetadataDecorator < Draper::Decorator
	delegate_all

	def to_hash()
		{
			id: id.to_s,
			animated: animated,
			store_filename: store_filename,
			md5_hash: md5_hash,
			original_filename: original_filename,
			uploader: uploader,
			upload_time: upload_time.to_ms,
			width: width,
			height: height
		}
  end
end