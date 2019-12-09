class AddOriginalFilenameToPhotoMetadata < ActiveRecord::Migration[5.2]
  def change
    add_column :photo_metadata, :original_filename, :string, null: false, index: true
  end
end
