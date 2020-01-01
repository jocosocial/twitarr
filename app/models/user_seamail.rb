# == Schema Information
#
# Table name: user_seamails
#
#  id          :bigint           not null, primary key
#  last_viewed :datetime
#  seamail_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_user_seamails_on_seamail_id  (seamail_id)
#  index_user_seamails_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (seamail_id => seamails.id)
#  fk_rails_...  (user_id => users.id)
#

class UserSeamail < ApplicationRecord
  belongs_to :user
  belongs_to :seamail
end
