class CreateUserEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :user_events do |t|
      t.bigint :user_id, null: false, index: true
      t.uuid :event_id, null: false, index: true
      t.boolean :acknowledged_alert, null: false, default: false
    end

    add_foreign_key :user_events, :users, column: :user_id
    add_foreign_key :user_events, :events, column: :event_id
  end
end
