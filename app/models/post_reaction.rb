# == Schema Information
#
# Table name: post_reactions
#
#  id             :bigint           not null, primary key
#  stream_post_id :bigint
#  reaction_id    :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_post_reactions_on_stream_post_id  (stream_post_id)
#  index_post_reactions_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (reaction_id => reactions.id) ON DELETE => cascade
#  fk_rails_...  (stream_post_id => reactions.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class PostReaction < ApplicationRecord
    #field :rn, as: :reaction, type: String
    #field :un, as: :username, type: String

    belongs_to :reaction, inverse_of: :post_reactions
    #belongs_to :forum_post, inverse_of: :post_reactions
    belongs_to :stream_post, inverse_of: :post_reactions
    belongs_to :user, inverse_of: :post_reactions
    
    validates :reaction_id, :user_id, presence: true
end
