class CreateStreamPosts < ActiveRecord::Migration[5.2]
  def change
    create_table :stream_posts, id: :bigint do |t|
      t.bigint :author, null: false, index: true
      t.bigint :original_author, null: false
      t.string :text, null: false
      t.bigint :location_id, index: true
      t.boolean :locked, null: false, default: false
      t.bigint :parent_id, index: true

      t.timestamps
    end

    add_foreign_key :stream_posts, :users, column: :author, on_delete: :cascade
    add_foreign_key :stream_posts, :users, column: :original_author, on_delete: :cascade
    add_foreign_key :stream_posts, :locations, column: :location_id, on_delete: :nullify
    add_foreign_key :stream_posts, :stream_posts, column: :parent_id, on_delete: :nullify

    add_index :stream_posts, 'to_tsvector(\'english\', text)', using: :gin, name: 'index_stream_posts_text'
  end
end
