class SeamailDecorator < Draper::Decorator
  delegate_all
  include ActionView::Helpers::TextHelper

  def to_meta_hash(current_username = '', count_is_unread = false)
    {
        id: id.to_s,
        users: usernames.map { |x| 
          u = User.get(x)
          h = { 
            username: u.username, 
            display_name: u.display_name, 
            last_photo_updated: u.last_photo_updated.to_ms 
          }
          h
        },
        subject: subject,
        message_count: seamail_count,
        timestamp: last_message.to_ms,
        is_unread: messages.any? { |message| message.read_users.exclude?(current_username) },
        count_is_unread: count_is_unread
    }
  end

  def to_hash(options = {}, current_username = '', count_is_unread = false)
    {
        id: id.to_s,
        users: usernames.map { |x| 
          u = User.get(x)
          h = { 
            username: u.username, 
            display_name: u.display_name, 
            last_photo_updated: u.last_photo_updated.to_ms 
          }
          h
        },
        subject: subject,
        messages: messages.map { |x| x.decorate.to_hash(options, current_username) }.compact,
        message_count: seamail_count,
        timestamp: last_message.to_ms,
        is_unread: messages.any? { |message| message.read_users.exclude?(current_username) },
        count_is_unread: count_is_unread
    }
  end

end
