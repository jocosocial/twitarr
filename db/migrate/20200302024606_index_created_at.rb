class IndexCreatedAt < ActiveRecord::Migration[6.0]
  def change
    add_index :stream_posts, :created_at
    add_index :seamail_messages, :created_at
    add_index :announcements, :updated_at
    add_index :events, [:start_time, :end_time]
    remove_index :events, :start_time
  end
end
