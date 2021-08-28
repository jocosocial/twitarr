# frozen_string_literal: true

class PostReactionDecorator < Draper::Decorator
  delegate_all

  def to_hash
    {
        reaction: reaction.name,
        user: user.decorate.gui_hash
    }
  end
end
