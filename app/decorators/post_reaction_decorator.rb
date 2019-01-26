class PostReactionDecorator < Draper::Decorator
  delegate_all

  def to_hash
    {
        reaction: reaction,
        user: {
          username: username,
          display_name: User.display_name_from_username(username),
          last_photo_updated: User.last_photo_updated_from_username(username).to_ms
        }
    }
  end
end
