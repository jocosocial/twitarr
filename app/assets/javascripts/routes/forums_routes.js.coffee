Twitarr.ForumsLoadingRoute = Twitarr.LoadingRoute.extend()

Twitarr.ForumsIndexRoute = Ember.Route.extend
  beforeModel: ->
    @transitionTo('forums.page', 0)

Twitarr.ForumsPageRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.ForumMeta.page(params.page)

  actions:
    reload: ->
      @refresh()

Twitarr.ForumsDetailRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.Forum.get(params.id, params.page).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('forums')
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    controller.scroll()
    controller.setupUpload()

  actions:
    reload: ->
      @refresh()

Twitarr.ForumsEditRoute = Ember.Route.extend
  model: (params) ->
    Twitarr.ForumPost.get(params.forum_id, params.post_id).fail((response)=>
      if response.responseJSON?.error?
        alert(response.responseJSON.error)
      else
        alert('Something went wrong. Please try again later.')
      @transitionTo('stream')
    )
  
  setupController: (controller, model) ->
    this._super(controller, model)
    if(model.status isnt 'ok')
      alert model.status
      return
    controller.set 'model', model.forum_post
    pics = Ember.A()
    pics.push (photo.id) for photo in model.forum_post.photos
    controller.set('photo_ids', pics)
    controller.setupUpload()

Twitarr.ForumsNewRoute = Ember.Route.extend
  setupController: (controller, model) ->
    this._super(controller, model)
    controller.setupUpload()
