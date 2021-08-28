# frozen_string_literal: true

# == Schema Information
#
# Table name: sections
#
#  id         :bigint           not null, primary key
#  category   :string
#  enabled    :boolean          default(TRUE), not null
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_sections_on_category  (category)
#  index_sections_on_name      (name) UNIQUE
#

class Section < ApplicationRecord
  default_scope { order(category: :asc, name: :asc) }

  def self.add(section, category)
    Section.find_or_create_by(name: section, category: category)
  rescue StandardError => e
    logger.error e
  end

  def self.enabled?(section)
    section.blank? || Section.find_by(name: section).enabled
  rescue StandardError
    true
  end

  def self.toggle(section, enabled)
    doc = Section.find_by(name: section)
    if doc
      doc.enabled = enabled
      doc.save
      doc
    end
  end

  def self.repopulate_sections
    Section.delete_all
    sections = %w(forums stream seamail calendar deck_plans games karaoke search registration)
    categories = %w(global Kraken cruise_monkey rainbow_monkey)
    categories.each do |category|
      sections.each do |section|
        name = section
        name = "#{category}_#{section}" unless category == 'global'
        Section.add(name, category)
      end
    end
    Section.add('cruise_monkey_advanced_sync', 'cruise_monkey')
  end
end
