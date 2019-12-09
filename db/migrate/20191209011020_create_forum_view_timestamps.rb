class CreateForumViewTimestamps < ActiveRecord::Migration[5.2]
  def change
    create_table :forum_view_timestamps do |t|
      t.bigint :user_id, null: false, index: true
      t.bigint :forum_id, null: false, index: true
      t.datetime :view_time, null: false
    end

    add_foreign_key :forum_view_timestamps, :users, column: :user_id
    add_foreign_key :forum_view_timestamps, :forums, column: :forum_id

    add_index :forum_view_timestamps, [:user_id, :forum_id], unique: true
  end
end
