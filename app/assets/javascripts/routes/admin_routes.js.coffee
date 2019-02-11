Twitarr.AdminUsersRoute = Ember.Route.extend
  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/admin/users/#{encodeURIComponent(params.text)}").fail((response)=>
      if response.status? && response.status == 401
        alert('Access Denied.')
        @transitionTo('index')
        return
      alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

  setupController: (controller, model) ->
    this._super(controller, model)

  actions:
    reload: ->
      @refresh()
    
    edit_profile: (username) ->
      if !!username
        @transitionTo('admin.profile', username)
    
    search: (text) ->
      if !!text
        @transitionTo('admin.users', text)

Twitarr.AdminProfileRoute = Ember.Route.extend
  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/admin/user/#{params.username}/profile").fail((response)=>
      if response.status? && response.status == 401
        alert('Access Denied.')
        @transitionTo('index')
        return
      alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )
  
  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status isnt 'ok'
      if model.error?
        alert model.error
      else
        alert 'Something went wrong. Try again later.'
    else
      controller.set('errors', Ember.A())
      controller.set('model', model.user)

  actions:
    save: (user) ->
      self = this
      $.post("#{Twitarr.api_path}/admin/user/#{user.username}", {
        role: user.role
        status: user.status
        email: user.email
        display_name: user.display_name,
        real_name: user.real_name,
        pronouns: user.pronouns,
        home_location: user.home_location,
        room_number: user.room_number,
        mute_reason: user.mute_reason,
        ban_reason: user.ban_reason
      }).fail((response) =>
        if response.responseJSON?.error?
          alert response.responseJSON.error
        else if response.responseJSON?.errors?
          self.controller.set('errors', response.responseJSON.errors)
        else
          alert 'Something went wrong. Try again later.'
      ).then((response) =>
        if (response.status isnt 'ok')
          alert response.status
        else
          self.controller.set('errors', Ember.A())
          alert('Profile saved.')
          @refresh()
      )

    # activate: (username) ->
    #   $.post("#{Twitarr.api_path}/admin/user/#{username}/activate").then (data) =>
    #     if (data.status isnt 'ok')
    #       alert data.status
    #     else
    #       @refresh()

    reset_password: (username) ->
      if confirm('Are you sure you want to reset this user\'s password to "seamonkey"?')
        $.post("#{Twitarr.api_path}/admin/user/#{username}/reset_password").fail((response) =>
          if response.status? && response.status == 401
            alert('Access Denied.')
            @transitionTo('index')
            return
          else if response.responseJSON?.error?
            alert(response.responseJSON.error)
          else
            alert 'Something went wrong. Try again later.'
          return
        ).then((data) =>
          alert('Password reset.')
          @refresh()
        )

    reset_photo: (username) ->
      if confirm('Are you sure you want to reset this user\'s photo?')
        $.post("#{Twitarr.api_path}/admin/user/#{username}/reset_photo").fail((response) =>
          if response.status? && response.status == 401
            alert('Access Denied.')
            @transitionTo('index')
            return
          else if response.responseJSON?.error?
            alert(response.responseJSON.error)
          else
            alert 'Something went wrong. Try again later.'
          return
        ).then((data) =>
          if (data.status isnt 'ok')
            alert data.status
          else
            alert('Photo reset.')
            @refresh()
        )

Twitarr.AdminSearchRoute = Ember.Route.extend
  model: (params) ->
    text: params.text

  actions:
    search: (text) ->
      if !!text
        @transitionTo('admin.users', text)

Twitarr.AdminAnnouncementsRoute = Ember.Route.extend
  model: ->
    $.getJSON("#{Twitarr.api_path}/admin/announcements").fail((response)=>
      if response.status? && response.status == 401
        alert('Access Denied.')
        @transitionTo('index')
        return
      alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status isnt 'ok'
      alert model.status
    else
      controller.set('model', model.announcements)
    controller.set('model.text', null)
    controller.set('model.valid_until', moment().add(4, 'hours').format('YYYY-MM-DDTHH:mm'))
    controller.set('model.errors', Ember.A())

  actions:
    new: (text, valid_until) ->
      self = this
      $.post("#{Twitarr.api_path}/admin/announcements", { text: text, valid_until: valid_until }).fail((response) =>
        if response.responseJSON?.error?
          self.controller.set('errors', [response.responseJSON.error])
        else if response.responseJSON?.errors?
          self.controller.set('errors', response.responseJSON.errors)
        else
          alert 'Announcement could not be created. Please try again later. Or try again someplace without so many seamonkeys.'
      ).then((response) =>
        if (response.status isnt 'ok')
          alert response.status
        else
          @refresh()
      )

Twitarr.AdminUploadScheduleRoute = Ember.Route.extend
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.setupUpload()
