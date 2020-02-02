class CreateReactions < ActiveRecord::Migration[5.2]
  def change
    create_table :reactions, id: :bigint do |t|
      t.string :name, null: false
    end

    add_index :reactions, :name

    create_table :post_reactions, id: :bigint do |t|
      t.bigint :stream_post_id, index: true
      t.bigint :reaction_id, null: false
      t.bigint :user_id, null: false, index: true
    end

    add_foreign_key :post_reactions, :stream_posts, column: :stream_post_id, on_delete: :cascade
    add_foreign_key :post_reactions, :reactions, column: :reaction_id, on_delete: :cascade
    add_foreign_key :post_reactions, :users, column: :user_id
  end
end
