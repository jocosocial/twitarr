class ForumPostDecorator < BaseDecorator
  delegate_all

  def to_hash(locked, user = nil, last_view = nil, options = {})
    post_user = User.get(author)
    ret = {
        id: id.to_s,
        forum_id: forum.id.to_s,
        author: {
          username: post_user.username,
          display_name: post_user.display_name,
          last_photo_updated: post_user.last_photo_updated.to_ms
        },
        thread_locked: locked,
        text: format_text(text, options),
        timestamp: timestamp.to_ms,
        photos: decorate_photos,
        reactions: BaseDecorator.reaction_summary(reactions, user&.username)
    }
    ret[:new] = (timestamp > last_view) unless last_view.nil?
    ret
  end

  def decorate_photos
    return [] unless photos
    photos.map { |x| 
      begin
        img = PhotoMetadata.find(x)
        { 
          id: x, 
          animated: img.animated,
          sizes: img.sizes
        } 
      rescue Mongoid::Errors::DocumentNotFound
      end
    }.compact
  end
end
