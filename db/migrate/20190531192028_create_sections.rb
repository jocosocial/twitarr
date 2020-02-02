class CreateSections < ActiveRecord::Migration[5.2]
  def change
    create_table :sections do |t|
      t.string :name
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end
    add_index :sections, :name, unique: true
  end
end
