class Reaction
  include Mongoid::Document

  field :_id, type: String, as: :name

  def self.add_reaction(reaction)
    begin
      doc = Reaction.new(name:reaction)
      doc.upsert
      doc
    rescue Exception => e
      logger.error e
    end
  end

  def self.valid_reaction?(reaction)
    (reaction.nil? || reaction.empty?) || Reaction.where(name: reaction).exists?
  end
end