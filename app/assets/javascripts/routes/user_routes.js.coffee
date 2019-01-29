Twitarr.UserIndexRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.User.get()
  
  setupController: (controller, model) ->
    # Clear state when loading this form
    controller.errors = Ember.A()
    model.current_password = null
    model.new_password = null
    model.confirm_password = null
    controller.set('model', model)

Twitarr.UserProfileRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.UserProfile.get(params.username)

Twitarr.UserNewRoute = Ember.Route.extend
  model: ->
    Twitarr.UserNew.load()
  
  setupController: (controller, model) ->
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
    # Clear state when loading this form
    controller.errors = Ember.A()
    controller.loading = false
    model.username = null
    model.registration_code = null
    model.new_password = null
    model.confirm_password = null
    controller.set('model', model)