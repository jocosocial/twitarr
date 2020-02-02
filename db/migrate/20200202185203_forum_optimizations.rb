class ForumOptimizations < ActiveRecord::Migration[6.0]
  def up
    add_column :forums, :forum_posts_count, :integer, null: false, default: 0
    add_column :forums, :last_post_user_id, :bigint

    add_foreign_key :forums, :users, column: :last_post_user_id

    Forum.reset_column_information
    Forum.all.each do |forum|
      Forum.update_counters forum.id, forum_posts_count: forum.posts.length
      forum.update(last_post_user_id: forum.posts.last.author)
    end
  end

  def down
    remove_foreign_key :forums, :users, column: :last_post_user_id
    remove_column :forums, :forum_posts_count
    remove_column :forums, :last_post_user_id
  end
end
