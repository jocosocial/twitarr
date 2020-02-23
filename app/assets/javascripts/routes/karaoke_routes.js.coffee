Twitarr.KaraokeRoute = Ember.Route.extend
  queryParams: {
    letter: {
      refreshModel: true
    }
    artist: {
      refreshModel: true
    }
    song: {
      refreshModel: true
    }
  }

  setupController: (controller, model) ->
    this._super(controller, model)

  model: (params) ->
    Twitarr.Karaoke.create(letter: params.letter, search_artist: params.artist, search_title: params.song)
