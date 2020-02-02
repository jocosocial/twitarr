class PostReactionDecorator < Draper::Decorator
  delegate_all

  def to_hash
    {
        reaction: reaction,
        user: {
          username: user.username,
          display_name: user.display_name,
          last_photo_updated: user.last_photo_updated.to_ms
        }
    }
  end
end
