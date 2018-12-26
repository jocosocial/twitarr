class RegistrationCode
  include Mongoid::Document

  field :_id, type: String, as: :code
  field :bd, as: :banned, type: Boolean, default: false

  def self.add_code(code)
    begin
      doc = RegistrationCode.new(code:code)
      doc.upsert
      doc
    rescue Exception => e
      logger.error e
    end
  end

  def self.valid_code?(code)
    regcode = RegistrationCode.where(code: code)
    regcode.exists? && !regcode.first.banned
  end
end