Twitarr.StreamLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.StreamIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo('stream.page', mostRecentTime())

Twitarr.StreamPageRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.page(params.page).fail((response) =>
      @transitionTo('help')
    )

  actions:
    reload: ->
      @transitionTo('stream.page', mostRecentTime())
  
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.setupUpload()
    controller.set('model.as_mod', false)

Twitarr.StreamStarPageRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.star_page(params.page).fail((response) =>
      @transitionTo('help')
    )

  actions:
    reload: ->
      @transitionTo('stream.star_page', mostRecentTime())

Twitarr.StreamMentionsRoute = Ember.Route.extend
  model: (params) ->
    @transitionTo('stream.mentions_page', params.username, mostRecentTime())

Twitarr.StreamMentionsPageRoute = Ember.Route.extend
  model: (params) ->
    @set('username', params.username)
    Twitarr.StreamPost.mentions_page(params.username, params.page).fail((response) =>
      @transitionTo('help')
    )
  
  setupController: (controller, model) ->
    this._super(controller, model)
    @set('controller.model.username', @get('username'))

  actions:
    reload: ->
      @transitionTo('stream.mentions_page', mostRecentTime())

Twitarr.StreamAuthorRoute = Ember.Route.extend
  model: (params) ->
    @transitionTo('stream.author_page', params.username, mostRecentTime())

Twitarr.StreamAuthorPageRoute = Ember.Route.extend
  model: (params) ->
    @set('username', params.username)
    Twitarr.StreamPost.author_page(params.username, params.page).fail((response) =>
      @transitionTo('help')
    )
  
  setupController: (controller, model) ->
    this._super(controller, model)
    @set('controller.model.username', @get('username'))

  actions:
    reload: ->
      @transitionTo('stream.author_page', mostRecentTime())

Twitarr.StreamViewRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.StreamPost.view(params.id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('stream.page', mostRecentTime())
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
      @transitionTo('stream.page', mostRecentTime())
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
