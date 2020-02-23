Twitarr.KaraokeController = Twitarr.Controller.extend
  queryParams: ['letter']
  letter: null

  actions:
    karaoke_search_clear: ->
      @set('model.letter', null)
      @set('model.search_artist', null)
      @set('model.search_song', null)

    karaoke_letter: (value) ->
      @set('model.letter', value)
