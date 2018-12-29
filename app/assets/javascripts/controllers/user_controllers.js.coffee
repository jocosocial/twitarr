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
    
    save_comment: ->
      $.post("#{Twitarr.api_path}/user/profile/#{@get('username')}/personal_comment", { comment: @get('comment') })

Twitarr.UserNewController = Twitarr.ObjectController.extend
  errors: null

  actions:
    save: ->
      self = this
      Twitarr.UserNew.save(
        @get('registration_code'),
        @get('new_username'),
        @get('display_name'),
        @get('email'), 
        @get('new_password'), 
        @get('new_password2'), 
        @get('security_question'), 
        @get('security_answer')
      ).then (response) -> 
        if response.status is 'ok'
          self.get('controllers.application').login(response.user)
          self.transitionToRoute('stream')
        else if response.errors?
          self.set 'errors', response.errors
        else
          alert 'Something went wrong. Try again later.'

Twitarr.UserLoginController = Twitarr.ObjectController.extend
  error: null

  actions:
    login: ->
      self = this
      Twitarr.UserLogin.login(@get('username'), @get('password')).fail (response) ->
        self.set 'error', response.responseJSON.status
        return
      .then (response) ->
        if response.status is 'ok'
          self.set('username', '')
          self.set('password', '')
          $.getJSON("#{Twitarr.api_path}/user/whoami").then (data) =>
            self.get('controllers.application').login(data.user)
            if data.need_password_change
              self.transitionToRoute('user')
              alert('You need to change your password before you continue')
            else
              self.transitionToRoute('stream')
        else 
           self.set 'error', response.status

Twitarr.UserForgotPasswordController = Twitarr.ObjectController.extend
  errors: Ember.A()
  loading: false

  actions:
    user_forgot_password: ->
      self = this
      Twitarr.UserForgotPassword.getSecurityQuestion(
        @get('username'), @get('email')
      ).fail (response) ->
        self.set 'errors', response.responseJSON.errors
      .then (response) ->         
        if response.status is 'ok'
          self.set('errors', Ember.A())
          self.set('security_question', response.security_question)
        else
          alert 'Something went wrong. Try again later.'

    user_reset_password: ->
      self = this

      if @get('new_password') != @get('confirm_password')
        alert "New Password and Confirm New Password do not match!"
        return

      @set('loading', true)
      Twitarr.UserForgotPassword.resetPassword(
        @get('username'), @get('email'), @get('security_answer'), @get('new_password')
      ).fail (response) ->
        self.set('loading', false)
        self.set 'errors', response.responseJSON.errors
      .then (response) ->
        self.set('loading', false)
        if response.status is 'ok'
          self.set('errors', Ember.A())
          alert(response.message)
          self.transitionToRoute('user.login')
        else
          alert 'Something went wrong. Try again later.'