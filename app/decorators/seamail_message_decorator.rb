class SeamailMessageDecorator < BaseDecorator
  delegate_all

  def to_hash(options = {})
    {
      id: id.to_s,
      author: {
        username: author,
        display_name: User.display_name_from_username(author),
        last_photo_updated: User.last_photo_updated_from_username(author),
      },
      text: replace_emoji(clean_text_with_cr(text, options), options),
      timestamp: timestamp,
      read_users: read_users.map { |user| 
        {
          username: user,
          display_name: User.display_name_from_username(user),
          last_photo_updated: User.last_photo_updated_from_username(user)
        }
      }
    }
  end

end
