# frozen_string_literal: true

class ForumPostDecorator < BaseDecorator
  delegate_all

  def to_hash(current_user = nil, last_view = nil, options = {})
    ret = {
      id: id.to_s,
      forum_id: forum_id.to_s,
      author: user.decorate.gui_hash,
      thread_locked: forum.locked,
      text: format_text(text, options),
      timestamp: created_at.to_ms,
      photos: decorate_photos,
      reactions: BaseDecorator.reaction_summary(post_reactions, current_user&.id)
    }
    ret[:new] = (created_at > last_view) unless last_view.nil?
    ret
  end

  def decorate_photos
    return [] unless post_photos

    post_photos.map do |img|
      {
        id: img.photo_metadata.id,
        animated: img.photo_metadata.animated,
        sizes: img.photo_metadata.sizes
      }
    end.compact
  end
end
