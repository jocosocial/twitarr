class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events, id: :uuid do |t|
      t.string :title, index: true, null: false
      t.string :description
      t.string :location
      t.datetime :start_time, index: true, null: false
      t.datetime :end_time
      t.boolean :official, index: true

      t.timestamps
    end

    add_index :events, 'to_tsvector(\'english\', title)', using: :gin, name: 'index_events_search_title'
    add_index :events, 'to_tsvector(\'english\', description)', using: :gin, name: 'index_events_search_desc'
    add_index :events, 'to_tsvector(\'english\', location)', using: :gin, name: 'index_events_search_loc'
  end
end
