Twitarr.UserIndexRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.User.get()

Twitarr.UserProfileRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.UserProfile.get(params.username)

Twitarr.UserNewRoute = Ember.Route.extend
  model: ->
    Twitarr.UserNew.load()

Twitarr.UserLoginRoute = Ember.Route.extend
  model: ->
    Twitarr.UserLogin