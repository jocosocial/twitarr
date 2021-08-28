# frozen_string_literal: true

class SectionDecorator < BaseDecorator
  delegate_all

  def to_hash
    {
        name: name.to_s,
        category: category.to_s,
        enabled: enabled
    }
  end
end
