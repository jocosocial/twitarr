# frozen_string_literal: true

# == Schema Information
#
# Table name: user_stars
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  starred_user_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_user_stars_on_user_id_and_starred_user_id  (user_id,starred_user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (starred_user_id => users.id)
#  fk_rails_...  (user_id => users.id)
#

class UserStar < ApplicationRecord
  belongs_to :user, class_name: 'User', inverse_of: :user_stars
  belongs_to :starred_user, class_name: 'User', inverse_of: :starred_by_users
end
