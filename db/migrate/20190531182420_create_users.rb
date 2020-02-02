class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users, id: :bigint do |t|
      t.string :username
      t.string :password
      t.integer :role
      t.string :status
      t.string :email
      t.string :display_name
      t.datetime :last_login
      t.datetime :last_viewed_alerts
      t.string :photo_hash
      t.datetime :last_photo_updated, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :room_number
      t.string :real_name
      t.string :home_location
      t.string :current_location
      t.string :registration_code
      t.string :pronouns
      t.string :mute_reason
      t.string :ban_reason
      t.string :mute_thread

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :display_name
    add_index :users, :registration_code, unique: true
  end
end
