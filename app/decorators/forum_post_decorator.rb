class ForumPostDecorator < BaseDecorator
  delegate_all

  def to_hash(current_user = nil, last_view = nil, options = {})
    ret = {
        id: id.to_s,
        forum_id: forum_id.to_s,
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        thread_locked: forum.locked,
        text: format_text(text, options),
        timestamp: created_at.to_ms,
        photos: decorate_photos,
        reactions: BaseDecorator.reaction_summary(post_reactions, current_user&.username)
    }
    ret[:new] = (created_at > last_view) unless last_view.nil?
    ret
  end

  def decorate_photos
    return [] unless post_photos

    photo_metadatas.map do |img|
      {
        id: img.id,
        animated: img.animated,
        sizes: img.sizes
      }
    end.compact
  end
end
