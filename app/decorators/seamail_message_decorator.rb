class SeamailMessageDecorator < BaseDecorator
  delegate_all

  def to_hash(options = {})
    {
        author: author,
        author_display_name: User.display_name_from_username(author),
        author_last_photo_updated: User.last_photo_updated_from_username(author),
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
