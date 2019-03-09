# noinspection RubyResolve
class StreamPostDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::DateHelper

  def to_hash(username = nil, options = {})
    user = User.get(author)
    result = {
        id: as_str(id),
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        locked: locked,
        timestamp: timestamp.to_ms,
        text: format_text(text, options),
        reactions: BaseDecorator.reaction_summary(reactions, username),
        parent_chain: parent_chain
    }
    unless photo.blank?
      begin
        img = PhotoMetadata.find(photo)
        result[:photo] = { id: photo, animated: img.animated, sizes: img.sizes }
      rescue Mongoid::Errors::DocumentNotFound
      end
    end
    if options.has_key? :remove
      options[:remove].each { |k| result.delete k }
    end
    result
  end

end
