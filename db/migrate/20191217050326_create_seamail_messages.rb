class CreateSeamailMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :seamail_messages do |t|
      t.bigint :seamail_id, null: false, index: true
      t.bigint :author, null: false, index: true
      t.bigint :original_author, null: false
      t.string :text, null: false
      t.bigint :read_users, null: false, array: true, default: []

      t.timestamps
    end

    add_foreign_key :seamail_messages, :seamails, column: :seamail_id
    add_foreign_key :seamail_messages, :users, column: :author
    add_foreign_key :seamail_messages, :users, column: :original_author

    add_index :seamail_messages, 'to_tsvector(\'english\', text)', using: :gin, name: 'index_seamail_messages_text'
  end
end
