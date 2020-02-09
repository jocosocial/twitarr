class ChangePhotoMetadataPkey < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'uuid-ossp'
    remove_foreign_key :post_photos, :photo_metadata, column: :photo_metadata_id

    add_column :photo_metadata, :uuid, :uuid, default: "uuid_generate_v4()", null: false

    change_table :post_photos do |t|
      t.rename :photo_metadata_id, :old_photo_metadata_id
      t.uuid :photo_metadata_id
    end

    PostPhoto.all.each do |photo|
      metadata = PhotoMetadata.find_by(id: photo.old_photo_metadata_id)
      photo.photo_metadata_id = metadata.uuid
      photo.save!(validate: false)
    end

    change_table :photo_metadata do |t|
      t.remove :id
      t.rename :uuid, :id
    end

    execute "ALTER TABLE photo_metadata ADD PRIMARY KEY (id);"

    change_table :post_photos do |t|
      t.remove :old_photo_metadata_id
      t.change :photo_metadata_id, :uuid, null: false
    end
    add_foreign_key :post_photos, :photo_metadata, column: :photo_metadata_id
  end
end
