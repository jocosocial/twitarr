class ForumPostDateIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :forum_posts, :created_at
    add_index :forum_posts, [:forum_id, :created_at]
  end
end
