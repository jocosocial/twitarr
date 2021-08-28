# frozen_string_literal: true

module CruiseMonkeyHelper
  include Twitter::TwitterText::Autolink

  def cm_auto_link(text)
    auto_link text, CRUISE_MONKEY_OPTIONS
  end

  # private
  def self.prepare_cruise_monkey_link(entity, attributes)
    attributes.delete :href
    attributes.delete :class
    attributes.delete :title
    if entity[:hashtag]
      attributes['cm-hashtag'] = (entity[:hashtag]).to_s
    elsif entity[:screen_name]
      attributes['cm-user'] = (entity[:screen_name]).to_s
    elsif entity[:url]
      attributes['cm-link'] = (entity[:url]).to_s
    end
  end

  CRUISE_MONKEY_OPTIONS = {
      link_attribute_block: lambda { |entity, attributes| prepare_cruise_monkey_link(entity, attributes) },
      username_include_symbol: false
  }.freeze
end
