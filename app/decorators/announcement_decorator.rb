class AnnouncementDecorator < BaseDecorator
  delegate_all
  include Twitter::Autolink

  def to_hash(options = {})
    user = User.get(author)
    ret = {
        id: as_str(id),
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        text: format_text(text, options),
        timestamp: timestamp.to_ms
    }
    ret
  end

  def to_admin_hash(options = {})
    {
        id: as_str(id),
        author: author,
        text: format_text(text, options),
        timestamp: timestamp.to_ms,
        valid_until: valid_until.to_ms
    }
  end

end