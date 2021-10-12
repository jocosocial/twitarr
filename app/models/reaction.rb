# frozen_string_literal: true

# == Schema Information
#
# Table name: reactions
#
#  id   :bigint           not null, primary key
#  name :string           not null
#
# Indexes
#
#  index_reactions_on_name  (name)
#

class Reaction < ApplicationRecord
  has_many :post_reactions, class_name: 'PostReaction', inverse_of: :reaction, dependent: :destroy

  def self.add_reaction(reaction)
    Reaction.find_or_create_by(name: reaction)
  rescue StandardError => e
    logger.error e
  end

  def self.valid_reaction?(reaction)
    reaction.blank? || Reaction.exists?(name: reaction)
  end
end
