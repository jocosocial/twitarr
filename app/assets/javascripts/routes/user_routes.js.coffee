Twitarr.UserIndexRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.User.get()

Twitarr.UserProfileRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.UserProfile.get(params.username)
