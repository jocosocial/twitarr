class EventDecorator < BaseDecorator
  delegate_all

  def to_meta_hash(username)
    result = {
        id: as_str(id),
        title: title,
        location: location,
        start_time: start_time.to_ms,
        official: official
    }
    result[:end_time] = end_time.to_ms unless end_time.blank?
    result[:following] = favorites.include? username
    result
  end

  def to_hash(username, options = {})
    result = to_meta_hash username
    result[:description] = format_text(description, options) unless description.blank?
    result
  end
end
