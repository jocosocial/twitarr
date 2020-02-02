class CreateUserSeamails < ActiveRecord::Migration[6.0]
  def change
    create_table :user_seamails do |t|
      t.bigint :user_id, null: false, index: true
      t.bigint :seamail_id, null: false, index: true
      t.datetime :last_viewed
    end

    add_foreign_key :user_seamails, :users, column: :user_id
    add_foreign_key :user_seamails, :seamails, column: :seamail_id
  end
end
