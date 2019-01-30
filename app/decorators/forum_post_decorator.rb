class ForumPostDecorator < BaseDecorator
  delegate_all

  def to_hash(username = nil, last_view = nil, options = {})
    ret = {
        id: id.to_s,
        forum_id: forum.id.to_s,
        author: {
          username: author,
          display_name: User.display_name_from_username(author),
          last_photo_updated: User.last_photo_updated_from_username(author).to_ms
        },
        text: twitarr_auto_linker(replace_emoji(clean_text_with_cr(text, options), options), options),
        timestamp: timestamp.to_ms,
        photos: decorate_photos,
        hash_tags: hash_tags,
#        location: location,
        mentions: mentions,
        reactions: BaseDecorator.reaction_summary(reactions, username)
    }
    ret[:new] = (timestamp > last_view) unless last_view.nil?
    ret
  end

  def decorate_photos
    return [] unless photos
    photos.map { |x| 
      begin
        { id: x, animated: !x.blank? && PhotoMetadata.find(x).animated } 
      rescue Mongoid::Errors::DocumentNotFound
      end
    }.compact
  end
end
