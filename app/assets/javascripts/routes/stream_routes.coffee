Twitarr.StreamLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.StreamIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo('stream.page', mostRecentTime())

Twitarr.StreamPageRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.page(params.page)

  actions:
    reload: ->
      @transitionTo('stream.page', mostRecentTime())
  
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.setupUpload()
    controller.set('model.as_mod', false)

Twitarr.StreamStarPageRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.star_page(params.page)

  actions:
    reload: ->
      @transitionTo('stream.star_page', mostRecentTime())

Twitarr.StreamViewRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.view(params.id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    controller.set('model', model)
    controller.set('model.base_reply_text', "@#{model.author.username} ")
    controller.set('model.reply_text', "@#{model.author.username} ")
    controller.setupUpload()

  actions:
    reload: ->
      @refresh()

Twitarr.StreamEditRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.get(params.id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      window.history.back()
      return
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    if(model.status isnt 'ok')
      alert model.status
      return
    controller.set 'model', model.post
    controller.setupUpload()

mostRecentTime = -> Math.ceil(new Date().valueOf() + 1000)
