class CreateUserForumViews < ActiveRecord::Migration[5.2]
  def change
    create_table :user_forum_views do |t|
      t.bigint :user_id, null: false, index: true
      t.jsonb :data, null: false, default: {}
    end

    add_foreign_key :user_forum_views, :users, column: :user_id, on_delete: :cascade
  end
end
