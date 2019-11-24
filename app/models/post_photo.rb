# == Schema Information
#
# Table name: post_photos
#
#  id                :bigint           not null, primary key
#  stream_post_id    :bigint
#  photo_metadata_id :bigint           not null
#  forum_post_id     :bigint
#
# Indexes
#
#  index_post_photos_on_stream_post_id  (stream_post_id)
#
# Foreign Keys
#
#  fk_rails_...  (forum_post_id => forum_posts.id) ON DELETE => cascade
#  fk_rails_...  (photo_metadata_id => photo_metadata.id) ON DELETE => cascade
#  fk_rails_...  (stream_post_id => stream_posts.id) ON DELETE => cascade
#

class PostPhoto < ApplicationRecord
  belongs_to :photo_metadata, inverse_of: :post_photos
  belongs_to :forum_post, inverse_of: :post_photos
  belongs_to :stream_post, inverse_of: :post_photo
end
