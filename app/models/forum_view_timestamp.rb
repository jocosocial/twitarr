# == Schema Information
#
# Table name: forum_view_timestamps
#
#  id        :bigint           not null, primary key
#  user_id   :bigint           not null
#  forum_id  :bigint           not null
#  view_time :datetime         not null
#
# Indexes
#
#  index_forum_view_timestamps_on_forum_id              (forum_id)
#  index_forum_view_timestamps_on_user_id               (user_id)
#  index_forum_view_timestamps_on_user_id_and_forum_id  (user_id,forum_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (forum_id => forums.id)
#  fk_rails_...  (user_id => users.id)
#

class ForumViewTimestamp < ApplicationRecord
  belongs_to :user
  belongs_to :forum
end
