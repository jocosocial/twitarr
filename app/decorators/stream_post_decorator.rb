# noinspection RubyResolve
class StreamPostDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::DateHelper

  def to_hash(current_user = nil, options = {})
    result = {
        id: id.to_s,
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        locked: locked,
        timestamp: created_at.to_ms,
        text: format_text(text, options),
        reactions: BaseDecorator.reaction_summary(post_reactions, current_user&.id),
        parent_chain: parent_chain
    }
    result[:photo] = { id: photo_metadata.id, animated: photo_metadata.animated, sizes: photo_metadata.sizes } if photo_metadata
    if options.has_key? :remove
      options[:remove].each { |k| result.delete k }
    end
    result
  end

end
