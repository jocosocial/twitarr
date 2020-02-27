class StreamPostDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::DateHelper

  def to_hash(current_user = nil, options = {})
    result = {
      id: id.to_s,
      author: user.decorate.gui_hash,
      locked: locked,
      timestamp: created_at.to_ms,
      text: format_text(text, options),
      reactions: BaseDecorator.reaction_summary(post_reactions, current_user&.id),
      parent_chain: parent_chain
    }
    result[:photo] = { id: photo_metadata.id, animated: photo_metadata.animated, sizes: photo_metadata.sizes } if photo_metadata
    options[:remove].each { |k| result.delete k } if options.key? :remove
    result
  end
end
