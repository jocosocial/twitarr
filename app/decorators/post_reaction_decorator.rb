class PostReactionDecorator < Draper::Decorator
  delegate_all

  def to_hash
    user = User.get(username)
    ret = {
        reaction: reaction,
        user: {
          username: username,
          display_name: user.username,
          last_photo_updated: user.last_photo_updated.to_ms
        }
    }
    ret
  end
end
