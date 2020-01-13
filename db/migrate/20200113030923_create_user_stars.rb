class CreateUserStars < ActiveRecord::Migration[6.0]
  def change
    create_table :user_stars do |t|
      t.bigint :user_id, null: false
      t.bigint :starred_user_id, null: false

      t.timestamps
    end

    add_index :user_stars, [:user_id, :starred_user_id], unique: true
    add_foreign_key :user_stars, :users, column: :user_id
    add_foreign_key :user_stars, :users, column: :starred_user_id
  end
end
