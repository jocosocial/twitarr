class DeleteReadUsersFromSeamailMessage < ActiveRecord::Migration[6.0]
  def up
    remove_column :seamail_messages, :read_users
  end

  def down
    add_column :seamail_messages, :read_users, :bigint, null: false, array: true, default: []
  end
end
