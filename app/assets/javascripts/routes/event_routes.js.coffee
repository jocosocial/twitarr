Twitarr.EventsLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.EventsIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo 'events.today'

Twitarr.EventsTodayRoute = Ember.Route.extend
  model: ->
    Twitarr.EventMeta.mine().fail((response)=>
      if response.status? && response.status == 401
        alert('You must be logged in to view your events.')
        @transitionTo('index')
        return
      else if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('help')
    )

  actions:
    reload: ->
      @refresh()

Twitarr.EventsDayRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.EventMeta.mine(params.date).fail((response)=>
      if response.status? && response.status == 401
        alert('You must be logged in to view your events.')
        @transitionTo('index')
        return
      else if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('help')
    )

  actions:
    reload: ->
      @refresh()

