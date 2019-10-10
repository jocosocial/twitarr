class AddTagsToStreamPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :stream_posts, :mentions, :string, null: false, array: true, default: []
    add_column :stream_posts, :hash_tags, :string, null: false, array: true, default: []
    add_index :stream_posts, :mentions, using: 'gin'
    add_index :stream_posts, :hash_tags, using: 'gin'
  end
end
