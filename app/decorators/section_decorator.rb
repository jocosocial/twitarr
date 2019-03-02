class SectionDecorator < BaseDecorator
  delegate_all

  def to_hash
    {
        name: name.to_s,
        enabled: enabled
    }
  end
end
