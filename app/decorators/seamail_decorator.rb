class SeamailDecorator < Draper::Decorator
  delegate_all
  include ActionView::Helpers::TextHelper

  def to_meta_hash(current_user_id = 0, count_is_unread = false)
    {
        id: id.to_s,
        users: users.map { |x| x.decorate.gui_hash },
        subject: subject,
        message_count: seamail_count(count_is_unread, current_user_id),
        timestamp: last_message.to_ms,
        is_unread: unread_for_user?(current_user_id),
        count_is_unread: count_is_unread && current_user_id > 0
    }
  end

  def to_hash(options = {}, current_user_id = 0, count_is_unread = false)
    {
        id: id.to_s,
        users: users.map { |x| { username: x.username, display_name: x.display_name, last_photo_updated: x.last_photo_updated.to_ms, pronouns: user.pronouns } },
        subject: subject,
        messages: seamail_messages.map { |x| x.decorate.to_hash(options, current_user_id, last_viewed(current_user_id)) }.compact,
        message_count: seamail_count(count_is_unread, current_user_id),
        timestamp: last_message.to_ms,
        is_unread: unread_for_user?(current_user_id),
        count_is_unread: count_is_unread && current_user_id > 0
    }
  end

end
