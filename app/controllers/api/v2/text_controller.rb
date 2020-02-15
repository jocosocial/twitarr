module Api
  module V2
    class TextController < ApiController
      FILE_CACHE_TIME = 10.minutes

      def index
        filename = params['filename'].strip.downcase.gsub(/[^\w-]/, '')
        file = Rails.cache.fetch("file:#{filename}", expires_in: FILE_CACHE_TIME) do
          File.read("public/text/#{filename}.json") if File.exist?("public/text/#{filename}.json")
        end
        if file
          render json: file
        else
          render(status: :not_found, json: { status: 'error', error: 'File not found.' })
        end
      end

      def time
        now = Time.now
        render json: {
          status: 'ok',
          epoch: now.to_ms,
          time: now.strftime('%B %d, %l:%M %P %Z'),
          offset: now.utc_offset
        }
      end

      def reactions
        render json: { status: 'ok', reactions: Reaction.all.map(&:id) }
      end

      def announcements
        render json: { status: 'ok', announcements: Announcement.valid_announcements.map { |x| x.decorate.to_hash(request_options) } }
      end
    end
  end
end
