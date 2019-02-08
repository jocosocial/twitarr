Twitarr.UserIndexRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.User.get().fail((response)=>
      if response.status? && response.status == 401
        alert('You must be logged in to view your profile.')
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('index')
    )
  
  setupController: (controller, model) ->
    this._super(controller, model)
    # Clear state when loading this form
    controller.errors = Ember.A()
    model.current_password = null
    model.new_password = null
    model.confirm_password = null
    controller.set('model', model)
    controller.setupUpload()

Twitarr.UserProfileRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.UserProfile.get(params.username).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

Twitarr.UserNewRoute = Ember.Route.extend
  model: ->
    Twitarr.UserNew.load()
  
  setupController: (controller, model) ->
    this._super(controller, model)
    # Clear state when loading this form
    controller.errors = Ember.A()
    controller.set('model', model)

Twitarr.UserLoginRoute = Ember.Route.extend
  model: ->
    Twitarr.UserLogin

Twitarr.UserForgotPasswordRoute = Ember.Route.extend
  model: ->
    Twitarr.UserForgotPassword
    
  setupController: (controller, model) ->
    this._super(controller, model)
    # Clear state when loading this form
    controller.errors = Ember.A()
    controller.loading = false
    model.username = null
    model.registration_code = null
    model.new_password = null
    model.confirm_password = null
    controller.set('model', model)