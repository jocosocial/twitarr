# == Schema Information
#
# Table name: photo_metadata
#
#  id                :uuid             not null, primary key
#  animated          :boolean          default(FALSE), not null
#  content_type      :string           not null
#  md5_hash          :string           not null
#  original_filename :string           not null
#  sizes             :jsonb            not null
#  store_filename    :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_photo_metadata_on_md5_hash  (md5_hash)
#  index_photo_metadata_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class PhotoMetadata < ApplicationRecord
  belongs_to :user
  has_many :post_photos, dependent: :destroy
end
