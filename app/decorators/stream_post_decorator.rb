# noinspection RubyResolve
class StreamPostDecorator < BaseDecorator
  delegate_all
  include ActionView::Helpers::DateHelper

  def to_hash(username = nil, options = {})
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
        reactions: BaseDecorator.reaction_summary(post_reactions, user.id),
        parent_chain: parent_chain
    }
=begin 
    unless photo.blank?
      begin
        img = PhotoMetadata.find(photo)
        result[:photo] = { id: photo, animated: img.animated, sizes: img.sizes }
      rescue Mongoid::Errors::DocumentNotFound
      end
    end 
=end
    if options.has_key? :remove
      options[:remove].each { |k| result.delete k }
    end
    result
  end

end
