class CreateSeamails < ActiveRecord::Migration[6.0]
  def change
    create_table :seamails do |t|
      t.string :subject, null: false
      t.datetime :last_update, null: false

      t.timestamps
    end

    add_index :seamails, 'to_tsvector(\'english\', subject)', using: :gin, name: 'index_seamails_subject'
  end
end
