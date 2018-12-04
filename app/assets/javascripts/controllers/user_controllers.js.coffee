Twitarr.UserIndexController = Twitarr.Controller.extend()


Twitarr.UserProfileController = Twitarr.ObjectController.extend
  photo_path: (-> "#{Twitarr.api_path}/user/photo/#{@get('username')}?full=true").property("username")

  actions:
    star: ->
      @get('model').star()