# == Schema Information
#
# Table name: user_comments
#
#  id                :bigint           not null, primary key
#  comment           :string           default(""), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  commented_user_id :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_user_comments_on_user_id_and_commented_user_id  (user_id,commented_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (commented_user_id => users.id)
#  fk_rails_...  (user_id => users.id)
#

class UserComment < ApplicationRecord
  belongs_to :user, class_name: 'User', foreign_key: :user_id, inverse_of: :user_comments
  belongs_to :commented_user, class_name: 'User', foreign_key: :commented_user_id, inverse_of: :commented_by_users

  validates :comment, length: { maximum: 5000 }
end
