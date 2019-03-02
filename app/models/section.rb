class Section
  include Mongoid::Document

  field :_id, as: :name, type: String
  field :en, as: :enabled, type: Boolean, default: true

  def self.add(section)
    begin
      doc = Section.new(name:section, enabled:true)
      doc.upsert
      doc
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
    doc = Section.find(section)
    doc.enabled = enabled
    doc.save!
    doc
  end
end
