Twitarr.KaraokeController = Twitarr.Controller.extend
  queryParams: ['letter']
  letter: null

  actions:
    karaoke_search_clear: ->
      @set('letter', null)
