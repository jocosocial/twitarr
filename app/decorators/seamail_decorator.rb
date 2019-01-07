class SeamailDecorator < Draper::Decorator
  delegate_all
  include ActionView::Helpers::TextHelper

  def to_meta_hash(message_prefix = '')
    {
        id: id.to_s,
        users: usernames.map { |x| { username: x, display_name: User.display_name_from_username(x), last_photo_updated: User.last_photo_updated_from_username(x) }},
        subject: subject,
        message_count: pluralize(seamail_count, message_prefix + 'message'),
        timestamp: last_message
    }
  end

  def to_hash(options = {}, message_prefix = '', current_username = '')
    {
        id: id.to_s,
        users: usernames.map { |x| { username: x, display_name: User.display_name_from_username(x), last_photo_updated: User.last_photo_updated_from_username(x) }},
        subject: subject,
        messages: messages.map { |x| x.decorate.to_hash(options, current_username) }.compact,
        message_count: pluralize(seamail_count, message_prefix + 'message'),
        timestamp: last_message
    }
  end

end
