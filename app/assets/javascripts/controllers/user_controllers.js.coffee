Twitarr.UserIndexController = Twitarr.ObjectController.extend
  needs: ['application']

  count: 0

  profile_pic: (->
    "#{Twitarr.api_path}/user/photo/#{@get('username')}?bust=#{@get('count')}"
  ).property('username', 'count')

  profile_pic_upload_url: (->
    "#{Twitarr.api_path}/user/photo"
  ).property()

  actions:
    save: ->
      result = @get('model').save()
      if(result)
        result.then (response) =>
          if response.status is 'ok'
            alert 'Profile was saved.'
          else
            alert response.status

    file_uploaded: ->
      @incrementProperty('count')


Twitarr.UserProfileController = Twitarr.ObjectController.extend
  photo_path: (-> "#{Twitarr.api_path}/user/photo/#{@get('username')}?full=true").property("username")

  actions:
    star: ->
      @get('model').star()

Twitarr.UserNewController = Twitarr.ObjectController.extend
  needs: ['application']

  actions:
    save: ->
      self = this
      Twitarr.UserNew.save(
        @get('new_username'), 
        @get('email'), 
        @get('new_password'), 
        @get('new_password2'), 
        @get('security_question'), 
        @get('security_answer')
      ).then (response) -> 
        if response.status is 'ok'
          self.get('controllers.application').login(response.user)
          self.transitionToRoute('stream')
        else
          alert(response.errors)  