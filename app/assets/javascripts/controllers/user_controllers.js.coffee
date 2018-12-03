Twitarr.UserController = Twitarr.ObjectController.extend
  photo_path: (-> "#{@get('api_path')}/user/photo/#{@get('username')}?full=true").property("username")

  actions:
    star: ->
      @get('model').star()