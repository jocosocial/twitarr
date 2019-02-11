class RegistrationCode
  include Mongoid::Document

  field :_id, type: String, as: :code

  def self.add_code(code)
    begin
      doc = RegistrationCode.new(code:code.gsub(/\s+/, ""))
      doc.upsert
      doc
    rescue Exception => e
      logger.error e
    end
  end

  def self.valid_code?(code)
    regcode = RegistrationCode.where(code: code)
    regcode.exists?
  end
end