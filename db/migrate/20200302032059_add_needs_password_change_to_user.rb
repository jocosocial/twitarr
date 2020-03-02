class AddNeedsPasswordChangeToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :needs_password_change, :boolean, null: false, default: false
  end
end
