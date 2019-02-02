class EventDecorator < BaseDecorator
  delegate_all

  def to_hash(username = nil, options = {})
    result = {
        id: as_str(id),
        title: title,
        location: location,
        start_time: start_time.to_ms,
        end_time: nil,
        official: official,
        description: nil,
        following: favorites.include?(username)
    }
    result[:end_time] = end_time.to_ms unless end_time.blank?
    result[:description] = format_text(description, options) unless description.blank?
    result
  end
end
