# == Schema Information
#
# Table name: registration_codes
#
#  id         :bigint           not null, primary key
#  code       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_registration_codes_on_code  (code) UNIQUE
#

class RegistrationCode < ApplicationRecord
  def self.add_code(code)
    begin
      RegistrationCode.find_or_create_by(code:code.upcase.gsub(/[^A-Z0-9]/, ""))
    rescue Exception => e
      logger.error e
    end
  end

  def self.valid_code?(code)
    regcode = RegistrationCode.where(code: code)
    regcode.exists?
  end
end
