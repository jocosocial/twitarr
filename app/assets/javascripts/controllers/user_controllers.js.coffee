Twitarr.UserIndexController = Twitarr.Controller.extend
  needs: ['application']

  count: 0
  errors: Ember.A()

  profile_pic: (->
    "#{Twitarr.api_path}/user/photo/#{@get('model.username')}?bust=#{@get('count')}"
  ).property('model.username', 'count')

  profile_pic_upload_url: (->
    "#{Twitarr.api_path}/user/photo"
  ).property()

  actions:
    save: ->
      self = this
      @get('model').save().fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else if response.responseJSON?.errors?
          self.set('errors', response.responseJSON.errors)
        else
          alert 'Something went wrong. Try again later.'
      ).then((response) =>
        if response.status is 'ok'
          self.set('errors', Ember.A())
          alert 'Profile saved.'
        else
          alert response.status
      )

    change_password: ->
      self = this

      if @get('model.new_password') != @get('model.confirm_password')
        alert "New Password and Confirm New Password do not match!"
        return
      
      result = @get('model').change_password(
        @get('model.current_password'), @get('model.new_password')
      ).fail (response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else if response.responseJSON?.errors?
          self.set 'errors', response.responseJSON.errors
        else
          alert('Unable to change password. Please try again later.')
      .then (response) =>
        if response.status is 'ok'
          self.set('errors', Ember.A())
          self.set('model.current_password', null)
          self.set('model.new_password', null)
          self.set('model.confirm_password', null)
          alert 'Password changed.'
        else
          alert 'Something went wrong. Try again later.'

    remove_photo: ->
      self = this

      if confirm('Are you sure you want to remove your profile photo?')
        @get('model').remove_photo().fail (response) =>
          alert 'Unable to remove photo. Try again later.'
        .then (response) =>
          if response.status is 'ok'
            self.set('count', 0)
          else
            alert 'Something went wrong. Try again later.'

    file_uploaded: ->
      @incrementProperty('count')


Twitarr.UserProfileController = Twitarr.Controller.extend
  photo_path: (-> "#{Twitarr.api_path}/user/photo/#{@get('model.username')}?full=true").property("model.username")

  logged_in_visible: (->
    @get('logged_in')
  ).property('logged_in')

  actions:
    star: ->
      @get('model').star()
    
    save_comment: ->
      $.post("#{Twitarr.api_path}/user/profile/#{@get('model.username')}/personal_comment", { comment: @get('model.comment') })
    
    admin_profile: (username) ->
      @transitionToRoute('admin.profile', username)

Twitarr.UserNewController = Twitarr.Controller.extend
  errors: null

  actions:
    save: ->
      if @get('model.new_password') != @get('model.new_password2')
        alert "New Password and Confirm New Password do not match!"
        return

      self = this
      Twitarr.UserNew.save(
        @get('model.registration_code'),
        @get('model.new_username'),
        @get('model.display_name'),
        @get('model.new_password')
      ).fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else if response.responseJSON?.errors?
          self.set('errors', response.responseJSON?.errors)
        else
          alert 'Something went wrong. Try again later.'
      ).then (response) -> 
        self.get('controllers.application').login(response.user)
        self.transitionToRoute('index')

Twitarr.UserLoginController = Twitarr.Controller.extend
  error: null

  actions:
    login: ->
      self = this
      Twitarr.UserLogin.login(@get('model.username'), @get('model.password')).fail((response) ->
        if response.responseJSON?.error?
          self.set 'error', response.responseJSON.error
        else
          self.set 'error', 'Something went wrong. Try again later.'
        return
      ).then((response) ->
        self.set('model.username', '')
        self.set('model.password', '')
        self.set('error', null)
        $.getJSON("#{Twitarr.api_path}/user/whoami").then((data) =>
          self.get('controllers.application').login(data.user)
          if data.need_password_change
            self.transitionToRoute('user')
            alert('You need to change your password before you continue.')
          else
            self.transitionToRoute('index')
        )
      )

Twitarr.UserForgotPasswordController = Twitarr.Controller.extend
  errors: Ember.A()
  loading: false

  actions:
    user_reset_password: ->
      self = this

      if @get('model.new_password') != @get('model.confirm_password')
        alert "New Password and Confirm New Password do not match!"
        return

      @set('loading', true)
      Twitarr.UserForgotPassword.resetPassword(
        @get('model.username'), @get('model.registration_code'), @get('model.new_password')
      ).fail((response) ->
        self.set('loading', false)
        self.set('errors', response.responseJSON.errors)
      ).then((response) ->
        self.set('loading', false)
        self.set('errors', Ember.A())
        alert(response.message)
        self.transitionToRoute('user.login')
      )
