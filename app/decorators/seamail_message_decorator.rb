class SeamailMessageDecorator < BaseDecorator
  delegate_all

  def to_hash(options = {}, current_user_id = 0, last_view = nil)
    unless options[:exclude_read_messages] && current_user_id != 0 && last_view && created_at > last_view
      {
        id: id.to_s,
        author: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        },
        text: format_text(text, options),
        timestamp: created_at.to_ms # ,
        # read_users: read_users.map do |user|
        #  {
        #    username: user,
        #    display_name: User.display_name_from_username(user),
        #    last_photo_updated: User.last_photo_updated_from_username(user).to_ms
        #  }
        # end
      }
    end
  end

end
