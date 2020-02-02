class SeamailMessageDecorator < BaseDecorator
  delegate_all

  def to_hash(options = {}, current_user_id = 0, last_view = nil)
    unless options[:exclude_read_messages] && current_user_id != 0 && last_view && created_at < last_view
      {
        id: id.to_s,
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        text: format_text(text, options),
        timestamp: created_at.to_ms,
        read_users: read_users.map do |read_user|
          {
            username: read_user.username,
            display_name: read_user.display_name,
            last_photo_updated: read_user.last_photo_updated.to_ms
          }
        end
      }
    end
  end
end
