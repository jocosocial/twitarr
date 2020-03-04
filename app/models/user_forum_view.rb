# == Schema Information
#
# Table name: user_forum_views
#
#  id          :bigint           not null, primary key
#  last_viewed :datetime         not null
#  forum_id    :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_user_forum_views_on_forum_id              (forum_id)
#  index_user_forum_views_on_user_id_and_forum_id  (user_id,forum_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (forum_id => forums.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class UserForumView < ApplicationRecord
  belongs_to :user
  belongs_to :forum
end
