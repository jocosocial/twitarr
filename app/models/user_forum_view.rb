# == Schema Information
#
# Table name: user_forum_views
#
#  id      :bigint           not null, primary key
#  data    :jsonb            not null
#  user_id :bigint           not null
#
# Indexes
#
#  index_user_forum_views_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class UserForumView < ApplicationRecord
  belongs_to :user

  def update_forum_view(forum_id)
    # rubocop:disable Rails/SkipsModelValidations
    UserForumView.where(id: id).update_all("data = jsonb_set(data, '{#{forum_id}}', '\"#{Time.now}\"'::jsonb)")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def mark_all_forums_read(participated_only)
    query = Forum.all
    query = query.includes(:posts).where('forum_posts.author = ?', id).references(:forum_posts) if participated_only

    now = Time.now
    timestamps = query.pluck(:id).each_with_object({}) { |id, hash| hash[id.to_s] = now }
    self.data = timestamps
    save
  end
end
