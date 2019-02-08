Twitarr.SearchIndexController = Twitarr.Controller.extend()

Twitarr.SearchResultsController = Twitarr.Controller.extend
  error: ''

  actions:
    user_search: ->
      @transitionToRoute('search.user_results', @get('model.query'))
    tweet_search: ->
      @transitionToRoute('search.tweet_results', @get('model.query'))
    forum_search: ->
      @transitionToRoute('search.forum_results', @get('model.query'))
    event_search: ->
      @transitionToRoute('search.event_results', @get('model.query'))

Twitarr.SearchUserResultsController = Twitarr.Controller.extend
  error: ''

Twitarr.SearchTweetResultsController = Twitarr.Controller.extend
  error: ''

Twitarr.SearchForumResultsController = Twitarr.Controller.extend
  error: ''

Twitarr.SearchEventResultsController = Twitarr.Controller.extend
  error: ''

Twitarr.SearchUserPartialController = Twitarr.Controller.extend()
