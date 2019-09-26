class CreatePostPhotos < ActiveRecord::Migration[5.2]
  def change
    create_table :post_photos, id: :bigint do |t|
      t.bigint :stream_post_id, index: true
      t.bigint :photo_metadata_id, null: false
    end

    add_foreign_key :post_photos, :stream_posts, column: :stream_post_id, on_delete: :cascade
    add_foreign_key :post_photos, :photo_metadata, column: :photo_metadata_id, on_delete: :cascade
  end
end
