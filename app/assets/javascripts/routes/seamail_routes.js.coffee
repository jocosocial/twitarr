Twitarr.SeamailLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.SeamailNewRoute = Ember.Route.extend
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.set('errors', Ember.A())
    controller.set('toUsers', Ember.A())
    controller.set('subject', '')
    controller.set('text', '')

Twitarr.SeamailIndexRoute = Ember.Route.extend
  queryParams: {
    as_mod: {
      refreshModel: true
    }
  }
  
  model: (params) ->
    Twitarr.SeamailMeta.list(params.as_mod).fail((response)=>
      if response.status? && response.status == 503
        if(response.responseJSON?.error?)
          alert(response.responseJSON.error)
        else
          alert('Something went wrong. Please try again later.')
        @transitionTo('help')
        return
      else if response.status? && response.status == 401
        alert('You must be logged in to view seamail.')
        @transitionTo('index')
        return
      else 
        alert('Something went wrong. Please try again later.')
        @transitionTo('index')
        return
    )

  actions:
    reload: ->
      @refresh()

Twitarr.SeamailDetailRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.Seamail.get(params.id, params.as_mod).fail((response)=>
      if response.status? && response.status == 503
        if response.responseJSON?.error?
          alert(response.responseJSON.error)
        else
          alert('Something went wrong. Please try again later.')
        @transitionTo('help')
        return
      else if response.status? && response.status == 401
        alert('You must be logged in to view seamail.')
        @transitionTo('index')
        return
      else if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('seamail')
      return
    )

  actions:
    reload: ->
      @refresh()
  
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.set('errors', Ember.A())
    controller.set('model.text', '')
