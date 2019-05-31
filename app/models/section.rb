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
  def self.add(section)
    begin
      Section.find_or_create_by(name: section) do |section|
        section.enabled = true
      end
    rescue Exception => e
      logger.error e
    end
  end

  def self.enabled?(section)
    begin
      (section.nil? || section.empty?) || Section.find(section).enabled
    rescue
      true
    end
  end

  def self.toggle(section, enabled)
    doc = Section.find_by_name(section)
    if doc
      doc.enabled = enabled
      doc.save!
    end
  end
end
