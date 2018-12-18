class PostReaction
    include Mongoid::Document

    field :rn, as: :reaction, type: String
    field :un, as: :username, type: String

    embedded_in :forum_post, inverse_of: :reactions
    embedded_in :stream_post, inverse_of: :reactions

    validates :reaction, :username, presence: true
    validate :validate_user, :validate_reaction

    def validate_user
        return if username.blank?
        unless User.exist? username
            errors[:base] << "#{username} is not a valid username"
        end
    end

    def validate_reaction
        return if reaction.blank?
        unless Reaction.valid_reaction? reaction
            errors[:base] << "#{reaction} is not a valid reaction"
        end
    end

    def username=(username)
        super User.format_username username
    end
end