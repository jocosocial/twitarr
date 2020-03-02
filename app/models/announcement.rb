# == Schema Information
#
# Table name: announcements
#
#  id              :bigint           not null, primary key
#  author          :bigint           not null
#  original_author :bigint           not null
#  text            :string           not null
#  valid_until     :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_announcements_on_author      (author)
#  index_announcements_on_updated_at  (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (author => users.id)
#  fk_rails_...  (original_author => users.id)
#

class Announcement < ApplicationRecord
  belongs_to :user, class_name: 'User', foreign_key: :author, inverse_of: :announcements

  scope :valid_announcements, -> { where('valid_until > ?', Time.now) }

  def self.new_announcements(since_ts)
    valid_announcements.where('updated_at > ?', since_ts).limit(1)
  end
end
