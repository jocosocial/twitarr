# == Schema Information
#
# Table name: sections
#
#  id         :bigint           not null, primary key
#  name       :string
#  enabled    :boolean          default(TRUE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_sections_on_name  (name) UNIQUE
#

class Section < ApplicationRecord
  default_scope { order(name: :asc) }
  def self.add(section)
    Section.find_or_create_by(name: section) do |doc|
      doc.enabled = true
    rescue StandardError => e
      logger.error e
    end
  end

  def self.enabled?(section)
    section.blank? || Section.find_by_name(section).enabled
  rescue StandardError
    true
  end

  def self.toggle(section, enabled)
    doc = Section.find_by_name(section)
    if doc
      doc.enabled = enabled
      doc.save
      doc
    end
  end
end
