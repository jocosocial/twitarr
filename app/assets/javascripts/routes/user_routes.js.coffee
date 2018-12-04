Twitarr.UserIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo 'profile'

Twitarr.UserProfileRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.UserProfile.get(params.username)
