class UpdateUserForumView < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute('TRUNCATE user_forum_views')

    add_column :user_forum_views, :forum_id, :bigint, null: false
    add_column :user_forum_views, :last_viewed, :datetime, null: false
    remove_column :user_forum_views, :data

    add_foreign_key :user_forum_views, :forums, column: :forum_id, on_delete: :cascade

    remove_index :user_forum_views, :user_id
    add_index :user_forum_views, :forum_id
    add_index :user_forum_views, [:user_id, :forum_id], unique: true
  end

  def down
    ActiveRecord::Base.connection.execute('TRUNCATE user_forum_views')

    add_column :user_forum_views, :data, :jsonb, null: false, default: {}

    remove_foreign_key :user_forum_views, :forums, column: :forum_id

    add_index :user_forum_views, :user_id
    remove_index :user_forum_views, :forum_id
    remove_index :user_forum_views, [:user_id, :forum_id]

    remove_column :user_forum_views, :forum_id
    remove_column :user_forum_views, :last_viewed
  end
end
