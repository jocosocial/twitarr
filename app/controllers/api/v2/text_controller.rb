class API::V2::TextController < ApplicationController
    skip_before_action :verify_authenticity_token

    def index
        render status: :not_found, json: {error: 'file not found'}  and return unless File.exists?("public/text/#{params['filename']}.json")
        
        file = File.read("public/text/#{params['filename']}.json")
        render json: file
    end
end