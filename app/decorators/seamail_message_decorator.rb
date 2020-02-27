class SeamailMessageDecorator < BaseDecorator
  delegate_all

  def to_hash(options = {}, current_user_id = 0, last_view = nil)
    unless options[:exclude_read_messages] && current_user_id != 0 && last_view && created_at < last_view
      {
        id: id.to_s,
        author: user.decorate.gui_hash,
        text: format_text(text, options),
        timestamp: created_at.to_ms,
        read_users: read_users.map { |x| x.decorate.gui_hash }
      }
    end
  end
end
