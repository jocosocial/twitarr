Twitarr.SearchRoute = Ember.Route.extend
  actions:
    search: (text) ->
      if !!text
        @transitionTo('search.results', text)

  setupController: (controller, model) ->
    this._super(controller, model)
    controller.set('text', '')

Twitarr.SearchResultsRoute = Ember.Route.extend
  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/search/all/#{encodeURIComponent(params.text)}").then((data) ->
      {
        status: data.status, 
        query: data.query,
        users: data.users,
        seamails: data.seamails,
        tweets: {matches: Ember.A(Twitarr.StreamPost.create(post)) for post in data.tweets.matches, count: data.count, more: data.more },
        forums: data.forums,
        events: {matches: Ember.A(Twitarr.EventMeta.create(event)) for event in data.events.matches, count: data.count, more: data.more }
      }
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status is 'ok'
      controller.set('error', null)
      controller.set('model', model)
    else
      controller.set('error', model.status)

Twitarr.SearchUserResultsRoute = Ember.Route.extend
  actions:
    search: (text) ->
      if !!text
        @transitionTo('search.user_results', text)

  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/search/users/#{encodeURIComponent(params.text)}")

  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status is 'ok'
      @controllerFor('search').set('text', model.text)
      controller.set('error', null)
      controller.set('model', model)
    else
      controller.set('error', model.status)

Twitarr.SearchTweetResultsRoute = Ember.Route.extend
  actions:
    search: (text) ->
      if !!text
        @transitionTo('search.tweet_results', text)

  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/search/tweets/#{encodeURIComponent(params.text)}").then((data) ->
      {status: data.status, query: data.query, tweets: {matches: Ember.A(Twitarr.StreamPost.create(post)) for post in data.tweets.matches, count: data.count, more: data.more }}
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status is 'ok'
      @controllerFor('search').set('text', model.text)
      controller.set('error', null)
      controller.set('model', model)
    else
      controller.set('error', model.status)

Twitarr.SearchForumResultsRoute = Ember.Route.extend
  actions:
    search: (text) ->
      if !!text
        @transitionTo('search.forum_results', text)

  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/search/forums/#{encodeURIComponent(params.text)}")

  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status is 'ok'
      @controllerFor('search').set('text', model.text)
      controller.set('error', null)
      controller.set('model', model)
    else
      controller.set('error', model.status)

Twitarr.SearchEventResultsRoute = Ember.Route.extend
  actions:
    search: (text) ->
      if !!text
        @transitionTo('search.event_results', text)

  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/search/events/#{encodeURIComponent(params.text)}").then((data)=>
      {status: data.status, query: data.query, events: {matches: Ember.A(Twitarr.EventMeta.create(event)) for event in data.events.matches, count: data.count, more: data.more }}
    )

  setupController: (controller, model) ->
    this._super(controller, model)
    if model.status is 'ok'
      @controllerFor('search').set('text', model.text)
      controller.set('error', null)
      controller.set('model', model)
    else
      controller.set('error', model.status)