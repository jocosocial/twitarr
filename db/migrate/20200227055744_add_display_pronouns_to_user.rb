class AddDisplayPronounsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :show_pronouns, :boolean, default: false, null: false
  end
end
