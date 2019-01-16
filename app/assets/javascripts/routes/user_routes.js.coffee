Twitarr.UserIndexRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.User.get()

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
    controller.security_question = null
    model.username = null
    model.email = null
    model.security_question = null
    model.security_answer = null
    model.new_password = null
    model.confirm_password = null
    controller.set('model', model)