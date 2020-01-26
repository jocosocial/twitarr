class CreateUserComment < ActiveRecord::Migration[6.0]
  def change
    create_table :user_comments do |t|
      t.bigint :user_id, null: false
      t.bigint :commented_user_id, null: false
      t.string :comment, null: false, default: ''

      t.timestamps
    end

    add_index :user_comments, [:user_id, :commented_user_id], unique: true
    add_foreign_key :user_comments, :users, column: :user_id
    add_foreign_key :user_comments, :users, column: :commented_user_id
  end
end
