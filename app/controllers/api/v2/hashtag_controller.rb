class API::V2::HashtagController < ApplicationController
  # noinspection RailsParamDefResolve
  skip_before_action :verify_authenticity_token
  before_filter :admin_required, :only => [:populate_hashtags]

  def populate_hashtags
    Hashtag.repopulate_hashtags
    values = Hashtag.all.map {|ht| ht.name }
    render json: {values: values}
  end

  def auto_complete
    query = params[:query]
    query = query[1..-1] if query[0] == '#'
    unless query && query.size >= Hashtag::MIN_AUTO_COMPLETE_LEN
      render status: :bad_request, json: {status: 'error', error: "Minimum length is #{Hashtag::MIN_AUTO_COMPLETE_LEN}"}
      return
    end
    values = Hashtag.auto_complete(query).map{|e|e[:id]}
    render json: {values: values}
  end

end
