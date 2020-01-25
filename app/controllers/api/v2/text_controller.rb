module Api
  module V2
    class TextController < ApplicationController
      def index
        filename = params['filename'].strip.downcase.gsub(/[^\w-]/, '')
        if File.exist?("public/text/#{filename}.json")
          file = File.read("public/text/#{filename}.json")
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
          offset: now.utc_offset / 3600
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
