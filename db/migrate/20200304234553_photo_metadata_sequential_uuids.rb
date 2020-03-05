class PhotoMetadataSequentialUuids < ActiveRecord::Migration[6.0]
  def up
    change_column :photo_metadata, :id, :uuid, default: "uuid_generate_v1mc()", null: false
  end

  def down
    change_column :photo_metadata, :id, :uuid, default: "uuid_generate_v4()", null: false
  end
end
