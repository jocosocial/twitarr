class CreateForums < ActiveRecord::Migration[5.2]
  def change
    create_table :forums do |t|
      t.string :subject, null: false
      t.datetime :last_post_time, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.boolean :sticky, null: false, default: false
      t.boolean :locked, null: false, default: false
    end

    add_index :forums, 'to_tsvector(\'english\', subject)', using: :gin, name: 'index_forums_subject'
    add_index :forums, [:sticky, :last_post_time], order: {sticky: :desc, last_post_time: :desc }

    add_column :forum_posts, :forum_id, :bigint, null: false
    add_foreign_key :forum_posts, :forums, column: :forum_id, on_delete: :cascade
  end
end
