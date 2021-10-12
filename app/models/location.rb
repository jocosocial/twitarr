# frozen_string_literal: true

# == Schema Information
#
# Table name: locations
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_locations_on_name  (name) UNIQUE
#

class Location < ApplicationRecord
  MIN_AUTO_COMPLETE_LEN = 3
  LIMIT = 10

  def self.add_location(location)
    Location.find_or_create_by(name: location)
  rescue StandardError => e
    logger.error e
  end

  def self.valid_location?(location)
    location.blank? || Location.exists?(name: location)
  end

  def self.auto_complete(prefix)
    return nil unless prefix && prefix.size >= MIN_AUTO_COMPLETE_LEN

    prefix = prefix.downcase
    Location.where(name: /^#{prefix}/i).asc(:name).limit(LIMIT)
  end
end
