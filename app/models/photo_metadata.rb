# == Schema Information
#
# Table name: photo_metadata
#
#  id                :bigint           not null, primary key
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
  # field :up, as: :uploader, type: String
  # field :ct, as: :content_type, type: String
  # field :fn, as: :store_filename, type: String
  # field :ut, as: :upload_time, type: Time
  # field :an, as: :animated, type: Boolean
  # field :hsh, as: :md5_hash, type: String
  # field :si, as: :sizes, type: Hash, default: {}

  # def serializable_hash(options)
  #   original_hash = super(options)
  #   Hash[original_hash.map {|k, v|
  #          [self.aliased_fields.invert[k] || k , as_str(v)]
  #        }]
  # end

  belongs_to :user
  has_many :post_photos, dependent: :destroy
end
