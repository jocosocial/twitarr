# frozen_string_literal: true

class AnnouncementDecorator < BaseDecorator
  delegate_all
  include Twitter::TwitterText::Autolink

  def to_hash(options = {})
    {
        id: id.to_s,
        author: user.decorate.gui_hash,
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
