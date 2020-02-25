Twitarr.Karaoke = Ember.Object.extend
  letter: null
  search_artist: null
  search_song: null
  song_list: Ember.A()
  loaded: false
  metadata_types: {
    'M': 'MIDI',
    'VR': 'Reduced Vocals',
    'Bowieoke': 'All-Bowie Karaoke',
    '(No Lyrics)': 'Missing Lyrics Display',
  }
  filtered: Ember.computed('letter', 'search_artist', 'search_song', ->
    letter = @get('letter')
    search_artist = @get('search_artist')
    search_song = @get('search_song')

    letter || (search_artist && search_artist.length > 2) || (search_song && search_song.length > 2)
  )
  filtered_songs: Ember.computed('song_list', 'letter', 'search_artist', 'search_song', ->
    letter = @get('letter')
    search_artist = @get('search_artist')
    search_song = @get('search_song')

    search_results = @get('song_list').reduce((results, artist) ->
      if letter
        if letter is '#'
          unless artist.name.match(/^\d/)
            return results
        else
          unless artist.name.toLowerCase().startsWith(letter.toLowerCase())
            return results

      if search_artist && search_artist.length > 2
        unless artist.name.toLowerCase().includes(search_artist.toLowerCase())
          return results

      matched_songs = []
      if search_song && search_song.length > 2
        matched_songs = artist.songs.filter((song) => song.title.toLowerCase().includes(search_song.toLowerCase()))
      else
        matched_songs = artist.songs

      if matched_songs.length > 0
        results.push({ name: artist.name, songs: matched_songs })

      return results
    , [])

    return search_results
  )

  init: ->
    metadata_types = @get('metadata_types')
    song_list = Ember.A()

    $.get("/JoCoKaraokeSongCatalog.txt").then((response) =>
      response.split(/\r?\n/).forEach((line) =>
        [artist, title, metadata] = line.split('\t')
        if artist && title
          songObj = { title: title, metadata: metadata_types[metadata] }

          artistObj = song_list.find((x) -> x.name == artist)

          if artistObj
            artistObj.songs.push(songObj)
          else
            artistObj = { name: artist, songs: [songObj] }
            song_list.push(artistObj)
      )
      @set('song_list', song_list)
      @set('loaded', true)
    )
