class CreatePhotoMetadata < ActiveRecord::Migration[5.2]
  def change
    create_table :photo_metadata, id: :bigint do |t|
      t.bigint :user_id, null: false, index: true
      t.string :content_type, null: false
      t.string :store_filename, null: false
      t.boolean :animated, null: false, default: false
      t.string :md5_hash, null: false, index: true
      t.jsonb :sizes, null: false, default: {}

      t.timestamps
    end

    add_foreign_key :photo_metadata, :users, column: :user_id
  end
end
