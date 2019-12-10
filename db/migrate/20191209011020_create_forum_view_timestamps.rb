class CreateForumViewTimestamps < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :forum_view_timestamps, :jsonb, null: false, default: {}
  end
end
