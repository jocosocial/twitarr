class SeamailMessageDecorator < BaseDecorator
  delegate_all

  def to_hash(options = {}, current_username = '')
    unless options[:exclude_read_messages] && current_username.length > 0 && read_users.include?(current_username)
      author_user = User.get(author)
      ret = {
        id: id.to_s,
        author: {
          username: author_user.username,
          display_name: author_user.display_name,
          last_photo_updated: author_user.last_photo_updated.to_ms,
        },
        text: format_text(text, options),
        timestamp: timestamp.to_ms,
        read_users: read_users.map { |user| 
          u = User.get(user)
          h = {
            username: u.username,
            display_name: u.display_name,
            last_photo_updated: u.last_photo_updated.to_ms
          }
          h
        }
      }
      ret
    end
  end

end
