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
    begin
      Location.find_or_create_by(name: location)
    rescue Exception => e
      logger.error e
    end
  end

  def self.valid_location?(location)
    (location.nil? || location.empty?) || Location.where(name: location).exists?
  end

  def self.auto_complete(prefix)
    unless prefix and prefix.size >= MIN_AUTO_COMPLETE_LEN
      return nil
    end
    prefix = prefix.downcase
    Location.where(name: /^#{prefix}/i).asc(:name).limit(LIMIT)
  end
end
