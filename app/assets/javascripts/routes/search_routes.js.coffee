Twitarr.SearchRoute = Ember.Route.extend
  actions:
    search: (text) ->
      if !!text
        @transitionTo('search.results', encodeURIComponent(text))

  setupController: (controller) ->
    controller.set('text', '')

Twitarr.SearchResultsRoute = Ember.Route.extend
  model: (params) ->
    $.getJSON("#{Twitarr.api_path}/search/all/#{params.text}")

  setupController: (controller, model) ->
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
    $.getJSON("#{Twitarr.api_path}/search/users/#{params.text}")

  setupController: (controller, model) ->
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
    $.getJSON("#{Twitarr.api_path}/search/tweets/#{params.text}")

  setupController: (controller, model) ->
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
    $.getJSON("#{Twitarr.api_path}/search/forums/#{params.text}")

  setupController: (controller, model) ->
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
    $.getJSON("#{Twitarr.api_path}/search/events/#{params.text}")

  setupController: (controller, model) ->
    if model.status is 'ok'
      @controllerFor('search').set('text', model.text)
      controller.set('error', null)
      controller.set('model', { events: (Twitarr.EventMeta.create(event) for event in model.events) })
    else
      controller.set('error', model.status)