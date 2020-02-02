class CreateAnnouncement < ActiveRecord::Migration[5.2]
  def change
    create_table :announcements, id: :bigint do |t|
      t.bigint :author, null: false, index: true
      t.bigint :original_author, null: false
      t.string :text, null: false
      t.datetime :valid_until, null: false

      t.timestamps
    end

    add_foreign_key :announcements, :users, column: :author
    add_foreign_key :announcements, :users, column: :original_author
  end
end
