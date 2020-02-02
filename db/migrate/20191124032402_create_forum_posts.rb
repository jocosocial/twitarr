class CreateForumPosts < ActiveRecord::Migration[5.2]
  def change
    create_table :forum_posts do |t|
      t.bigint :author, null: false, index: true
      t.bigint :original_author, null: false
      t.string :text, null: false
      t.string :mentions, null: false, array: true, default: []
      t.string :hash_tags, null: false, array: true, default: []

      t.timestamps
    end

    add_foreign_key :forum_posts, :users, column: :author
    add_foreign_key :forum_posts, :users, column: :original_author

    add_index :forum_posts, 'to_tsvector(\'english\', text)', using: :gin, name: 'index_forum_posts_text'
    add_index :forum_posts, :mentions, using: 'gin'
    add_index :forum_posts, :hash_tags, using: 'gin'
    add_index :forum_posts, :created_at, order: :desc

    add_column :post_photos, :forum_post_id, :bigint, index: true
    add_foreign_key :post_photos, :forum_posts, column: :forum_post_id, on_delete: :cascade

    add_column :post_reactions, :forum_post_id, :bigint, index: true
    add_foreign_key :post_reactions, :forum_posts, column: :forum_post_id, on_delete: :cascade
  end
end
