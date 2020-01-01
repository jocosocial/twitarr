# == Schema Information
#
# Table name: seamail_messages
#
#  id              :bigint           not null, primary key
#  author          :bigint           not null
#  original_author :bigint           not null
#  read_users      :bigint           default([]), not null, is an Array
#  text            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  seamail_id      :bigint           not null
#
# Indexes
#
#  index_seamail_messages_on_author      (author)
#  index_seamail_messages_on_seamail_id  (seamail_id)
#  index_seamail_messages_text           (to_tsvector('english'::regconfig, (text)::text)) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (author => users.id)
#  fk_rails_...  (original_author => users.id)
#  fk_rails_...  (seamail_id => seamails.id)
#

class SeamailMessage < ApplicationRecord
  belongs_to :seamail, inverse_of: :seamail_messages, dependent: :destroy
  belongs_to :user, class_name: 'User', foreign_key: :author, inverse_of: :seamail_messages_authored

  validates :text, presence: true, length: { maximum: 10000 }
  validates :author, :original_author, presence: true
end
