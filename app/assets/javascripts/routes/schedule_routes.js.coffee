Twitarr.ScheduleLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.ScheduleIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo 'schedule.today'

Twitarr.ScheduleTodayRoute = Ember.Route.extend
  model: ->
    Twitarr.EventMeta.all()

  actions:
    reload: ->
      @refresh()

Twitarr.ScheduleDayRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.EventMeta.all(params.date).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

  actions:
    reload: ->
      @refresh()

Twitarr.ScheduleDetailRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.Event.get(params.id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

Twitarr.ScheduleEditRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.Event.get_edit(params.id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

Twitarr.ScheduleUploadRoute = Ember.Route.extend
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.setupUpload()
