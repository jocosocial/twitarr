class AnnouncementDecorator < BaseDecorator
  delegate_all
  include Twitter::Autolink

  def to_hash(options = {})
    {
        id: id.to_s,
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        text: format_text(text, options),
        timestamp: created_at.to_ms
    }
  end

  def to_admin_hash(options = {})
    {
        id: id.to_s,
        author: user.username,
        text: format_text(text, options),
        timestamp: created_at.to_ms,
        valid_until: valid_until.to_ms
    }
  end

end