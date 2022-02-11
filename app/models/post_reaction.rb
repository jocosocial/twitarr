# frozen_string_literal: true

# == Schema Information
#
# Table name: post_reactions
#
#  id             :bigint           not null, primary key
#  stream_post_id :bigint
#  reaction_id    :bigint           not null
#  user_id        :bigint           not null
#  forum_post_id  :bigint
#
# Indexes
#
#  index_post_reactions_on_stream_post_id  (stream_post_id)
#  index_post_reactions_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (forum_post_id => forum_posts.id) ON DELETE => cascade
#  fk_rails_...  (reaction_id => reactions.id) ON DELETE => cascade
#  fk_rails_...  (stream_post_id => stream_posts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id)
#

class PostReaction < ApplicationRecord
  belongs_to :reaction, inverse_of: :post_reactions
  belongs_to :forum_post, inverse_of: :post_reactions, optional: true
  belongs_to :stream_post, inverse_of: :post_reactions, optional: true
  belongs_to :user, inverse_of: :post_reactions

  validates :reaction_id, :user_id
  validate :validate_association

  default_scope { includes(:user, :reaction).references(:users, :reactions) }

  def validate_association
    errors[:base] = 'Must be associated to a stream post or forum post' if stream_post_id.blank? && forum_post_id.blank?
  end
end
