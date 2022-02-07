# frozen_string_literal: true

module Api
  module V2
    class HashtagController < ApiController
      before_action :admin_required, only: [:populate_hashtags]

      def populate_hashtags
        Hashtag.repopulate_hashtags
        values = Hashtag.all.map(&:name)
        render json: { values: }
      end

      def auto_complete
        query = params[:query]
        query = query[1..] if query[0] == '#'
        unless query && query.size >= Hashtag::MIN_AUTO_COMPLETE_LEN
          render status: :bad_request, json: { status: 'error', error: "Minimum length is #{Hashtag::MIN_AUTO_COMPLETE_LEN}" }
          return
        end
        values = Hashtag.auto_complete(query).pluck(:name)
        render json: { values: }
      end
    end
  end
end
